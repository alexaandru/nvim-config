(local default-config {:width-ratio 0.7
                       :height-ratio 0.6
                       :preview {:width-ratio 0.5 :number false}
                       :keymaps {:close [:<Esc> :<C-c>]
                                 :select [:<CR> :<Tab>]
                                 :preview-toggle [:<C-p>]
                                 :scroll-preview-up [:<C-u>]
                                 :scroll-preview-down [:<C-d>]}
                       :prompt "Select: "})

(local empty-state {:filter-buf nil
                    :filter-close nil
                    :list-buf nil
                    :list-close nil
                    :preview-buf nil
                    :preview-close nil
                    :filter-text ""
                    :selected-idx 1
                    :selected-items {}
                    :items []
                    :filtered-items []
                    :all-items []
                    :preview-fn nil
                    :on-select nil
                    :on-multi-select nil
                    :source-fn nil
                    :setup-list-fn nil
                    :original-win nil
                    :dynamic-source false})

(local [UP DOWN] [:up :down])
(local keymaps {:i {:<Up> [:move-selection UP]
                    :<Down> [:move-selection DOWN]
                    :<Right> [:toggle-selection true :move-selection DOWN]
                    :<Left> [:toggle-selection false :move-selection UP]
                    :<C-n> [:move-selection DOWN]
                    :<C-p> [:move-selection UP]
                    :<PageUp> [:move-selection-page UP]
                    :<PageDown> [:move-selection-page DOWN]
                    :<C-u> [:move-selection-page UP]
                    :<C-d> [:move-selection-page DOWN]}
                :n {:j [:move-selection DOWN]
                    :k [:move-selection UP]
                    :<Down> [:move-selection DOWN]
                    :<Up> [:move-selection UP]
                    :<Right> [:toggle-selection true :move-selection DOWN]
                    :<Left> [:toggle-selection false :move-selection UP]
                    :<PageUp> [:move-selection-page UP]
                    :<PageDown> [:move-selection-page DOWN]
                    :<C-u> [:move-selection-page UP]
                    :<C-d> [:move-selection-page DOWN]}})

(local Picker {})
(set Picker.__index Picker)

(fn Picker.init [user-config]
  (let [dex-f #(vim.tbl_deep_extend :force $ $2)
        config (dex-f default-config (or user-config {}))
        instance (dex-f empty-state {:config config})]
    (setmetatable instance Picker)))

(fn split-chars [s]
  (vim.fn.split s "\\zs"))

;; fnlfmt: skip
(fn calculate-layout [config preview-enabled]
  (let [total-width (math.floor (* config.width-ratio vim.o.columns))
        total-height (math.floor (* config.height-ratio vim.o.lines))
        preview-width (if preview-enabled (math.floor (* total-width config.preview.width-ratio)) 0)
        list-width (- total-width preview-width)
        filter-height 1
        list-height (- total-height filter-height 1)
        start-row (math.floor (/ (- vim.o.lines total-height) 2))
        start-col (math.floor (/ (- vim.o.columns total-width) 2))]
    {:filter {:width list-width :height filter-height :row start-row :col start-col}
     :list {:width list-width :height list-height :row (+ start-row filter-height 1) :col start-col}
     :preview (if preview-enabled {:width preview-width :height total-height :row start-row :col (+ start-col list-width 1)})}))

(fn Picker.update-filter [self filter-text]
  (let [was-empty (= (length self.filter-text) 0)
        is-empty (= (length filter-text) 0)]
    (set self.filter-text filter-text)
    (if self.dynamic-source
        ;; If source-fn is dynamic (re-calls on filter change), use it
        (let [new-items (self.source-fn filter-text nil)]
          (set self.all-items new-items)
          (set self.filtered-items new-items))
        ;; Otherwise do local fuzzy matching
        (if is-empty
            (set self.filtered-items self.all-items)
            (let [strict-mode (string.find filter-text "^'")
                  search-text (if strict-mode (string.sub filter-text 2)
                                  filter-text)]
              (set self.filtered-items
                   (if strict-mode
                       (vim.fn.filter self.all-items #($2:find search-text))
                       (vim.fn.matchfuzzy self.all-items search-text))))))
    ;; Only reset index if we're actually filtering (not on initial empty->empty transition)
    (when (not (and was-empty is-empty))
      (set self.selected-idx 1)
      (set self.selected-items {}))))

(local o vim.api.nvim_set_option_value)
(local c vim.api.nvim_win_set_config)

(fn Picker.update-list-display [self]
  (let [buf self.list-buf
        items self.filtered-items]
    (when buf
      (o :modifiable true {: buf})
      (vim.api.nvim_buf_set_lines buf 0 -1 false items)
      (if self.setup-list-fn
          (self.setup-list-fn buf items))
      (o :modifiable false {: buf})
      (o :modified false {: buf})
      ;; Update multi-selection markers
      (vim.fn.sign_unplace "picker-selected" {:buffer buf})
      (each [idx _ (pairs self.selected-items)]
        (if (and (>= idx 1) (<= idx (length items)))
            (vim.fn.sign_place 0 "picker-selected" "PickerSelected" buf
                               {:lnum idx :priority 100})))
      (let [list-win (vim.fn.bufwinid buf)]
        (if (> list-win -1)
            (let [total-items (length items)
                  idx self.selected-idx
                  selected-count (length (vim.tbl_keys self.selected-items))
                  title (if (> selected-count 0)
                            (.. " Results " idx "/" total-items " ("
                                selected-count " selected) ")
                            (.. " Results " idx "/" total-items " "))]
              (c list-win {: title :title_pos :center})
              (vim.api.nvim_win_set_cursor list-win [idx 0])))))))

(fn Picker.update-preview [self]
  (if (and self.preview-buf self.preview-fn (> (length self.filtered-items) 0))
      (let [current-item (. self.filtered-items self.selected-idx)]
        (if current-item
            (let [preview-content (self.preview-fn current-item
                                                   self.selected-idx)]
              (o :modifiable true {:buf self.preview-buf})
              ;; All preview functions now return enhanced format
              (vim.api.nvim_buf_set_lines self.preview-buf 0 -1 false
                                          preview-content.content)
              ;; Set filetype based on filename if available
              (if preview-content.filename
                  (let [filetype (vim.filetype.match {:filename preview-content.filename})]
                    (when filetype
                      (o :filetype filetype {:buf self.preview-buf})
                      (pcall #(vim.treesitter.start self.preview-buf filetype)))))
              ;; Position cursor on specific line if provided
              (if preview-content.line
                  (let [preview-win (vim.fn.bufwinid self.preview-buf)]
                    (when (> preview-win -1)
                      (vim.api.nvim_win_set_cursor preview-win
                                                   [preview-content.line 0])
                      (vim.api.nvim_win_call preview-win
                                             #(vim.cmd "normal! zz")))))
              ;; Set search pattern for highlighting if provided
              (if preview-content.search-pattern
                  (let [preview-win (vim.fn.bufwinid self.preview-buf)]
                    (if (> preview-win -1)
                        (vim.api.nvim_win_call preview-win
                                               #(do
                                                  (vim.fn.setreg "/"
                                                                 preview-content.search-pattern)
                                                  (set vim.o.hlsearch true))))))
              ;; Apply diagnostic highlights if diagnostic info is provided
              (if preview-content.diagnostic
                  (let [diag preview-content.diagnostic
                        ns (vim.api.nvim_create_namespace "diagnostics-picker-preview")
                        severity-to-hl {1 "DiagnosticUnderlineError"
                                        2 "DiagnosticUnderlineWarn"
                                        3 "DiagnosticUnderlineInfo"
                                        4 "DiagnosticUnderlineHint"}
                        severity-to-line-hl {1 "DiagnosticVirtualTextError"
                                             2 "DiagnosticVirtualTextWarn"
                                             3 "DiagnosticVirtualTextInfo"
                                             4 "DiagnosticVirtualTextHint"}
                        line-hl (or (. severity-to-line-hl diag.severity)
                                    "DiagnosticVirtualTextError")
                        underline-hl (or (. severity-to-hl diag.severity)
                                         "DiagnosticUnderlineError")]
                    (vim.api.nvim_buf_clear_namespace self.preview-buf ns 0 -1)
                    ;; Highlight the entire line with a subtle background
                    (vim.api.nvim_buf_set_extmark self.preview-buf ns diag.lnum
                                                  0
                                                  {:end_line (+ diag.lnum 1)
                                                   :hl_group line-hl
                                                   :priority 50})
                    ;; Apply diagnostic underline to the specific range
                    (when (and diag.col (>= diag.col 0))
                      (let [end-col (or diag.end_col (+ diag.col 1))]
                        (vim.api.nvim_buf_set_extmark self.preview-buf ns
                                                      diag.lnum diag.col
                                                      {:end_col end-col
                                                       :hl_group underline-hl
                                                       :priority 100})))))
              (o :modifiable false {:buf self.preview-buf})
              (o :modified false {:buf self.preview-buf}))
            ;; Update preview window title with footer info
            (if self.preview-fn
                (let [preview-win (vim.fn.bufwinid self.preview-buf)]
                  (if (> preview-win -1)
                      (let [cursor (vim.api.nvim_win_get_cursor preview-win)
                            line (. cursor 1)
                            total-lines (vim.api.nvim_buf_line_count self.preview-buf)
                            percentage (if (> total-lines 0)
                                           (math.floor (* (/ line total-lines)
                                                          100))
                                           0)
                            title (.. " Preview " percentage "% ")]
                        (c preview-win {:title title :title_pos :center})))))))))

(fn Picker.move-selection [self direction]
  (let [max-idx (length self.filtered-items)]
    (when (> max-idx 0)
      (set self.selected-idx
           (if (= direction UP) (math.max 1 (- self.selected-idx 1))
               (= direction DOWN) (math.min max-idx (+ self.selected-idx 1))))
      (self:update-list-display)
      (self:update-preview))))

(fn Picker.move-selection-page [self direction]
  (let [max-idx (length self.filtered-items)
        list-win (vim.fn.bufwinid self.list-buf)]
    (if (and (> max-idx 0) (> list-win -1))
        (let [win-height (vim.api.nvim_win_get_height list-win)
              page-size (math.max 1 (- win-height 1))]
          (set self.selected-idx
               (if (= direction UP)
                   (math.max 1 (- self.selected-idx page-size))
                   (= direction DOWN)
                   (math.min max-idx (+ self.selected-idx page-size))))
          (self:update-list-display)
          (self:update-preview)))))

(fn Picker.toggle-selection [self select?]
  (let [idx self.selected-idx]
    (when (and (> (length self.filtered-items) 0)
               (<= idx (length self.filtered-items)))
      (if select?
          (tset self.selected-items idx true)
          (tset self.selected-items idx nil))
      (self:update-list-display))))

;; fnlfmt: skip
(fn Picker.close [self]
    (vim.schedule (fn []
                    (each [_ close-fn (pairs [self.filter-close self.list-close self.preview-close])]
                      (if (and close-fn (= (type close-fn) :function)) (pcall close-fn)))
                    (each [_ key (ipairs [:filter-buf :filter-close :list-buf :list-close :preview-buf :preview-close])]
                      (tset self key nil))
                    (set self.all-items []))))

(fn Picker.select-current [self split-mode]
  (if (> (length self.filtered-items) 0)
      (let [selected-count (length (vim.tbl_keys self.selected-items))]
        (if (and (> selected-count 0) self.on-multi-select)
            ;; Multi-selection mode: gather all selected items
            (let [selected-items []
                  on-multi-select-fn self.on-multi-select]
              (each [idx _ (pairs self.selected-items)]
                (table.insert selected-items (. self.filtered-items idx)))
              (self:close)
              (vim.schedule #(on-multi-select-fn selected-items
                                                 self.original-win split-mode)))
            ;; Single selection mode: use current item
            (if self.on-select
                (let [selected-item (. self.filtered-items self.selected-idx)
                      on-select-fn self.on-select]
                  (self:close)
                  (vim.schedule #(on-select-fn selected-item self.selected-idx
                                               self.original-win split-mode))))))))

;; fnlfmt: skip
(fn Picker.setup-filter-window [self buf]
    (o :buftype :prompt {: buf})
    (vim.api.nvim_buf_call buf #(vim.cmd "setl nobl bt=prompt bh=delete noswf"))
    (vim.api.nvim_create_autocmd [:TextChanged :TextChangedI]
                                 {:buffer buf
                                  :callback #(let [lines (vim.api.nvim_buf_get_lines buf 0 -1 false)
                                                   filter-text (or (and (> (length lines) 0) (string.sub (. lines 1) 3)) "")]
                                               (self:update-filter filter-text)
                                               (self:update-list-display)
                                               (self:update-preview)
                                               ;; Reset modified state to prevent E37
                                               (vim.api.nvim_set_option_value :modified false {: buf}))}))

(fn Picker.setup-list-window [self buf]
  (vim.api.nvim_buf_call buf #(vim.cmd "Scratchify"))
  (let [win (vim.fn.bufwinid buf)]
    (when (> win -1)
      (o :cursorline true {: win})
      (o :signcolumn "auto:2" {: win})
      (o :winhighlight
         "Normal:Normal,CursorLine:PmenuSel,FloatBorder:Normal,Cursor:CursorLine"
         {: win})))
  ;; Define sign for selected items with orange color
  (vim.api.nvim_set_hl 0 "PickerSelectedSign" {:fg "#ff8800" :bold true})
  (vim.fn.sign_define "PickerSelected"
                      {:text "▐" :texthl "PickerSelectedSign"})
  ;; Add autocmd to track cursor movements (including mouse clicks) and update selection
  (vim.api.nvim_create_autocmd :CursorMoved
                               {:buffer buf
                                :callback #(let [win (vim.fn.bufwinid buf)]
                                             (when (> win -1)
                                               (let [cursor (vim.api.nvim_win_get_cursor win)
                                                     line (. cursor 1)]
                                                 (when (and (<= line
                                                                (length self.filtered-items))
                                                            (not= line
                                                                  self.selected-idx))
                                                   (set self.selected-idx line)
                                                   (self:update-preview)))))}))

(fn setup-preview-window [buf config]
  (vim.api.nvim_buf_call buf #(vim.cmd "Scratchify"))
  (let [win (vim.fn.bufwinid buf)]
    (when (> win -1)
      (o :wrap false {: win})
      (o :number config.preview.number {: win})
      (o :cursorline false {: win})
      (o :winhighlight "Normal:Normal,FloatBorder:Normal" {: win})
      (o :foldenable false {: win})
      (o :syntax :enable {: buf}))))

(fn Picker.setup-keymaps [self close-keys select-keys]
  (let [filter-opts {:buffer self.filter-buf :silent true}
        list-opts {:buffer self.list-buf :silent true}
        imap #(vim.keymap.set :i $1 $2 $3)
        nmap #(vim.keymap.set :n $1 $2 $3)]
    ;; Close/select keys (data-driven across modes)
    (each [mode opts (pairs {:i filter-opts :n list-opts})]
      (each [_ key (ipairs close-keys)]
        (vim.keymap.set mode key #(self:close) opts))
      (each [_ key (ipairs select-keys)]
        (vim.keymap.set mode key #(self:select-current) opts)))
    ;; Split keymaps
    (each [mode opts (pairs {:i filter-opts :n list-opts})]
      (vim.keymap.set mode :<M-CR> #(self:select-current :vsplit) opts)
      (vim.keymap.set mode :<C-S-CR> #(self:select-current :split) opts))
    ;; Data-driven keymaps from top-level table
    (each [mode mappings (pairs keymaps)]
      (let [opts (if (= mode :i) filter-opts list-opts)]
        (each [key actions (pairs mappings)]
          (let [callback (fn []
                           (for [i 1 (length actions) 2]
                             (let [method (. actions i)
                                   arg (. actions (+ i 1))]
                               (: self method arg))))]
            (vim.keymap.set mode key callback opts)))))
    ;; Special keymaps with custom logic
    (imap "'" "'" filter-opts)
    (imap :<M-k>
          #(if self.preview-buf
               (let [preview-win (vim.fn.bufwinid self.preview-buf)]
                 (if (> preview-win -1)
                     (vim.fn.win_execute preview-win "normal! 5k"))))
          filter-opts)
    (imap :<M-j>
          #(if self.preview-buf
               (let [preview-win (vim.fn.bufwinid self.preview-buf)]
                 (if (> preview-win -1)
                     (vim.fn.win_execute preview-win "normal! 5j"))))
          filter-opts)
    (nmap :x
          #(let [idx self.selected-idx]
             (self:toggle-selection (not (. self.selected-items idx))))
          list-opts)
    ;; Redirect typing to filter buffer (excluding 'x' which is used for toggle)
    (let [chars "abcdefghijklmnopqrstuvwyzABCDEFGHIJKLMNOPQRSTUVWYZ0123456789-_./:'\"[]{}()<>!@#$%^&*+=~`|\\;,?"]
      (for [i 1 (length chars)]
        (let [char (string.sub chars i i)]
          (nmap char
                #(let [filter-win (vim.fn.bufwinid self.filter-buf)]
                   (when (> filter-win -1)
                     (vim.api.nvim_set_current_win filter-win)
                     (vim.api.nvim_feedkeys char :n false)))
                list-opts))))
    ;; Preview buffer keymaps
    (if self.preview-buf
        (let [preview-opts {:buffer self.preview-buf :silent true}]
          (each [_ key (ipairs close-keys)]
            (nmap key #(self:close) preview-opts))
          (each [_ key (ipairs select-keys)]
            (nmap key #(self:select-current) preview-opts))
          ;; Split keymaps for preview buffer
          (nmap :<S-CR> #(self:select-current :vsplit) preview-opts)
          (nmap :<C-S-CR> #(self:select-current :split) preview-opts)
          (nmap ":" #(let [filter-win (vim.fn.bufwinid self.filter-buf)]
                       (when (> filter-win -1)
                         (vim.api.nvim_set_current_win filter-win)
                         (vim.cmd.startinsert)))
                preview-opts)))))

(fn new-picker [_self source-fn opts]
  (vim.validate :source-fn source-fn :function)
  (let [picker (Picker.init opts.config)
        config picker.config
        close-keys config.keymaps.close
        select-keys config.keymaps.select
        preview-enabled (not= opts.preview-fn nil)
        {: float-win} (require :util)]
    ;; Initialize picker
    (doto picker
      (tset :original-win (vim.api.nvim_get_current_win))
      (tset :source-fn source-fn)
      (tset :preview-fn opts.preview-fn)
      (tset :on-select opts.on-select)
      (tset :on-multi-select opts.on-multi-select)
      (tset :setup-list-fn opts.setup-list-fn)
      (tset :dynamic-source (or opts.dynamic-source false))
      (tset :items (source-fn "" nil)))
    (doto picker
      (tset :all-items picker.items)
      (tset :filtered-items picker.items)
      (tset :selected-idx (or opts.initial-idx 1))
      (tset :filter-text ""))
    ;; Calculate layout
    (let [layout (calculate-layout config preview-enabled)]
      ;; Create filter window using float-win with custom border
      (let [filter-border (split-chars "╭─┬│┤─├│")
            (filter-buf filter-close) (float-win [""] layout.filter.width
                                                 layout.filter.height true
                                                 "Filter" filter-border)]
        (set picker.filter-buf filter-buf)
        (set picker.filter-close filter-close)
        (picker:setup-filter-window filter-buf)
        ;; Position filter window
        (let [filter-win (vim.fn.bufwinid filter-buf)]
          (when (> filter-win -1)
            (c filter-win {:relative :editor
                           :row layout.filter.row
                           :col layout.filter.col
                           :zindex 50})
            ;(o :winblend 0 {:win filter-win})
            (o :winhighlight "Normal:Normal,FloatBorder:Normal"
               {:win filter-win})
            (vim.fn.prompt_setprompt filter-buf "> "))))
      ;; Create list window using float-win with custom border
      (let [list-border (split-chars "├─┤│┴─╰│")
            (list-buf list-close) (float-win picker.filtered-items
                                             layout.list.width
                                             layout.list.height false "Results"
                                             list-border)]
        (set picker.list-buf list-buf)
        (set picker.list-close list-close)
        (picker:setup-list-window list-buf)
        ;; Position list window with initial title
        (let [list-win (vim.fn.bufwinid list-buf)
              total-items (length picker.filtered-items)
              title (.. " Results " picker.selected-idx "/" total-items " ")]
          (if (> list-win -1)
              (c list-win {:relative :editor
                           :row layout.list.row
                           :col layout.list.col
                           : title
                           :title_pos :center
                           :zindex 51})))
        ;; Create preview window if enabled
        (if layout.preview
            (let [preview-border (split-chars "┬─╮│╯─└│")
                  (preview-buf preview-close) (float-win [""]
                                                         layout.preview.width
                                                         layout.preview.height
                                                         false "Preview"
                                                         preview-border)]
              (set picker.preview-buf preview-buf)
              (set picker.preview-close preview-close)
              (setup-preview-window preview-buf config)
              ;; Position preview window
              (let [preview-win (vim.fn.bufwinid preview-buf)]
                (if (> preview-win -1)
                    (c preview-win
                       {:relative :editor
                        :row layout.preview.row
                        :col layout.preview.col})))))
        ;; Setup interactions
        (picker:setup-keymaps close-keys select-keys)
        ;; Initial display
        (picker:update-list-display)
        (picker:update-preview)
        ;; Focus filter window and enter insert mode
        (let [filter-win (vim.fn.bufwinid picker.filter-buf)]
          (when (> filter-win -1)
            (vim.api.nvim_set_current_win filter-win)
            (vim.cmd.startinsert)))))))

(setmetatable Picker {:__call new-picker})
