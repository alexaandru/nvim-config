;; picker.fnl - extui-based fuzzy picker
;; Uses vim._extui to render picker in cmdline area
;;
;; Inspired by https://github.com/comfysage/artio.nvim

(local View (require :picker.view))
(local config (require :picker.config))

(local picker {})

(local action-enum {:accept 0 :cancel 1})

;; Picker class
(local Picker {})
(set Picker.__index Picker)

(local hilights {:PickerNormal :NormalFloat
                 :PickerPrompt :Question
                 :PickerPointer :Special
                 :PickerMarker :WarningMsg
                 :PickerMatch :Search
                 :PickerCurrSel :PmenuSel})

;; Check if item is structured
(fn item-is-structured [item]
  (and (= (type item) :table) item.id item.v item.text))

;; Create actions for a picker instance
(fn make-actions [self]
  (let [wrap (fn [action-fn scheduled-fn]
               (fn []
                 (when (and (not self.closed)
                            (= (coroutine.status self.co) :suspended))
                   (pcall action-fn self)
                   (when scheduled-fn
                     (vim.schedule #(pcall scheduled-fn self))))))
        mark-and-move (fn [mark-value direction]
                        (wrap (fn [self]
                                (let [m (. self.matches self.idx)]
                                  (when m
                                    (let [item (. self.items (. m 1))]
                                      (self:mark item.id mark-value))))
                                (set self.idx
                                     (if (> direction 0)
                                         (math.min (length self.matches) (+ self.idx direction))
                                         (math.max 1 (+ self.idx direction))))
                                (self.view:trigger-show))))]
    {:up (wrap (fn [self]
                 (set self.idx (math.max 1 (- self.idx 1)))
                 (self.view:navigate)))
     :down (wrap (fn [self]
                   (set self.idx
                        (math.min (length self.matches) (+ self.idx 1)))
                   (self.view:navigate)))
     :accept (wrap (fn [self] (self:accept)))
     :cancel (wrap (fn [self] (self:cancel)))
     :mark (wrap (fn [self]
                   (let [m (. self.matches self.idx)]
                     (when m
                       (let [item (. self.items (. m 1))]
                         (self:mark item.id
                                    (not (. self.marked item.id))))))
                   (self.view:trigger-show)))
     :select (mark-and-move true 1)
     :deselect (mark-and-move false -1)
     :toggle-preview (wrap (fn [self] (self.view:togglepreview)))
     :page-up (wrap (fn [self]
                      (let [list-height (or self.view.win.height 10)
                            page-size (math.max 1 (- list-height 1))]
                        (set self.idx
                             (math.max 1 (- self.idx page-size)))
                        (self.view:navigate))))
     :page-down (wrap (fn [self]
                        (let [list-height (or self.view.win.height 10)
                              page-size (math.max 1 (- list-height 1))]
                          (set self.idx
                               (math.min (length self.matches)
                                         (+ self.idx page-size)))
                          (self.view:navigate))))
     :preview-scroll-up (wrap (fn [self] (self.view:scrollpreview :up)))
     :preview-scroll-down (wrap (fn [self] (self.view:scrollpreview :down)))
     :split (wrap (fn [self]
                    (set self.open-cmd :split)
                    (self:accept)))
     :vsplit (wrap (fn [self]
                     (set self.open-cmd :vsplit)
                     (self:accept)))
     :tabnew (wrap (fn [self]
                     (set self.open-cmd :tabnew)
                     (self:accept)))}))

;; Create new Picker
(fn Picker.new [_self props]
  (vim.validate "Picker.items" props.items :table)
  (vim.validate "Picker.fn" props.fn :function)
  (vim.validate "Picker.on-close" props.on-close :function)
  (local t (vim.tbl_deep_extend :force
                                {:closed false
                                 :prompt ""
                                 :input nil
                                 :idx 0
                                 :items []
                                 :matches []
                                 :marked {}}
                                (config.get) props))
  (if (not t.prompttext)
      (set t.prompttext (if t.opts.prompt-title
                            (string.format "%s %s" t.prompt t.opts.promptprefix)
                            t.opts.promptprefix)))
  (set t.input (or t.defaulttext ""))
  (setmetatable t Picker)
  ;; Create instance-specific actions (merging with any user-provided actions)
  (local default-actions (make-actions t))
  (local custom-actions (or t.actions {}))
  ;; Wrap function for custom actions
  (local wrap-action
         (fn [action-spec]
           (if (= (type action-spec) :table)
               ;; If it's a table with action-fn/scheduled-fn (from utils.make-setqflist)
               (let [action-fn action-spec.action-fn
                     scheduled-fn action-spec.scheduled-fn]
                 (fn []
                   (when (and (not t.closed)
                              (= (coroutine.status t.co) :suspended))
                     (pcall action-fn t)
                     (when scheduled-fn
                       (vim.schedule #(pcall scheduled-fn t))))))
               ;; Otherwise it's already a wrapped function, use as-is
               action-spec)))
  ;; Wrap custom actions
  (each [k v (pairs custom-actions)]
    (tset custom-actions k (wrap-action v)))
  (set t.actions (vim.tbl_extend :force default-actions custom-actions))
  (t:getitems "")
  (t:getmatches "")
  (set t.idx (if t.opts.preselect 1 0))
  t)

;; Get items, optionally filtering through get-items function
(fn Picker.getitems [self input]
  (set self.items (if self.get-items (self.get-items input) self.items))
  ;; Convert simple items to structured format
  (if (and (> (length self.items) 0)
           (not (item-is-structured (. self.items 1))))
      (set self.items (-> (vim.iter (ipairs self.items))
                          (: :map
                             (fn [id v]
                               (let [text (if (and self.format-item
                                                   (vim.is_callable self.format-item))
                                              (self.format-item v)
                                              v)
                                     text (or text v)]
                                 {: id : v : text})))
                          (: :totable)))))

;; Get matches by running sorter
(fn Picker.getmatches [self input-arg]
  (let [input (or input-arg self.input)]
    (self:getitems input)
    (set self.matches (self.fn self.items input))
    (table.sort self.matches (fn [a b] (> (. a 3) (. b 3))))))

;; Open the picker
(fn Picker.open [self]
  (set self.view (View:new self))
  ((coroutine.wrap (fn []
                     (self.view:open)
                     (self:initkeymaps)
                     (local (co ismain) (coroutine.running))
                     (assert (not ismain) "must be called from a coroutine")
                     (set self.co co)
                     (let [result (coroutine.yield)]
                       (self:close)
                       (if (or (= result action-enum.cancel)
                               (not= result action-enum.accept))
                           (if (and self.on-cancel
                                    (vim.is_callable self.on-cancel))
                               (self.on-cancel))
                           (let [current (and (. self.matches self.idx)
                                              (. (. self.matches self.idx) 1))]
                             (if current
                                 (let [item (. self.items current)]
                                   (if item
                                       (self.on-close item.v item.id
                                                      self.open-cmd)))))))))))

;; Close the picker
(fn Picker.close [self free]
  (when (not self.closed)
    (if self.view (self.view:close))
    (self:delkeymaps)
    (set self.closed true)
    (if free (self:free))))

;; Free memory
(fn Picker.free [self]
  (when self
    (set self.items nil)
    (set self.matches nil)
    (set self.marked nil)
    (vim.schedule #(collectgarbage :collect))))

;; Initialize keymaps
(fn Picker.initkeymaps [self]
  (let [ext (require :vim._extui.shared)
        opts {:buffer ext.bufs.cmd}]
    (if self.actions
        (: (vim.iter (pairs self.actions)) :each
           (fn [k v]
             (vim.keymap.set :i (string.format "<Plug>(picker-action-%s)" k) v
                             opts))))
    (if self.mappings
        (: (vim.iter (pairs self.mappings)) :each
           (fn [k v]
             (vim.keymap.set :i k (string.format "<Plug>(picker-action-%s)" v)
                             (vim.tbl_extend :force opts {:remap true})))))))

;; Delete keymaps
(fn Picker.delkeymaps [_self]
  (let [ext (require :vim._extui.shared)
        keymaps (vim.api.nvim_buf_get_keymap ext.bufs.cmd :i)
        keymaps (vim.iter (ipairs keymaps))]
    (keymaps:each (fn [_ v]
                    (if (or (string.match v.lhs "^<Plug>%(picker%-action%-")
                            (and v.rhs
                                 (string.match v.rhs
                                               "^<Plug>%(picker%-action%-")))
                        (vim.api.nvim_buf_del_keymap ext.bufs.cmd :i v.lhs))))))

;; Accept selection
(fn Picker.accept [self]
  (coroutine.resume self.co action-enum.accept))

;; Cancel picker
(fn Picker.cancel [self]
  (coroutine.resume self.co action-enum.cancel))

;; Fix index bounds
(fn Picker.fix [self]
  (set self.idx (math.max self.idx (if self.opts.preselect 1 0)))
  (set self.idx (math.min self.idx (length self.matches))))

;; Mark/unmark item for multi-selection
(fn Picker.mark [self idx yes]
  (tset self.marked idx (if (= yes nil)
                            true
                            yes)))

;; Get all marked item IDs
(fn Picker.getmarked [self]
  (-> (vim.iter (pairs self.marked))
      (: :map (fn [k v] (if v k nil)))
      (: :totable)))

;; Get current item
(fn Picker.getcurrent [self idx-arg]
  (var idx idx-arg)
  (when (not idx)
    (local i self.idx)
    (set idx (and (. self.matches i) (. (. self.matches i) 1))))
  (if idx (. self.items idx)))

;; Fuzzy sorter - simple and fast with strict mode support
(fn picker.fuzzy-sorter [lst input]
  (if (or (not lst) (= (length lst) 0))
      []
      (or (not input) (= (length input) 0))
      (vim.tbl_map (fn [v] [v.id [] 0]) lst)
      ;; Check for strict mode (starts with ')
      (string.find input "^'")
      (let [search-text (string.sub input 2)
            matches []]
        (each [_ item (ipairs lst)]
          (when (string.find item.text search-text 1 true)
            (table.insert matches [item.id [] 1])))
        matches)
      ;; Normal fuzzy matching
      (let [matches (vim.fn.matchfuzzy lst input {:key :text})]
        (vim.tbl_map (fn [item] [item.id [] 1]) matches))))

;; Pattern sorter (filters by regex pattern /pattern/)
(fn picker.pattern-sorter [lst input]
  (local pattern-match (string.match input "^/[^/]*/"))
  (local pattern (and pattern-match (string.match pattern-match "^/([^/]*)/$")))
  (-> (vim.iter lst)
      (: :map
         #(if (or (not pattern) (string.match $.text pattern)) [$.id [] 0]))
      (: :totable)))

;; Default simple fuzzy sorter (fast)
(set picker.sorter picker.fuzzy-sorter)

;; Setup global config
(fn picker.setup [cfg]
  (config.set (or cfg {})))

;; Generic picker with items
(fn picker.generic [items props]
  (picker.pick (vim.tbl_deep_extend :force
                                    {:fn picker.sorter
                                     :items items}
                                    props)))

;; Main pick function
(fn picker.pick [...]
  (: (Picker:new ...) :open))

;; vim.ui.select compatible interface
(fn picker.select [items opts on-choice start-opts]
  (picker.generic items
                  (vim.tbl_deep_extend :force
                                       {:prompt opts.prompt
                                        :on-close (fn [_ idx]
                                                    (on-choice (. items idx)
                                                               idx))
                                        :format-item (and opts.format_item
                                                          (fn [item]
                                                            (opts.format_item item)))}
                                       (or start-opts {}))))

(let [hl #(vim.api.nvim_set_hl 0 $ {:link $2 :default true})]
  (each [k v (pairs hilights)] (hl k v)))

picker
