;; picker/utils.fnl - Action helpers for picker

(local utils {})

;; Execute shell command and return lines
(fn cmd-callback [o]
  (local src (if (= o.code 0) o.stdout o.stderr))
  (vim.split src "\n" {:trimempty true}))

;; Create a command runner
(fn utils.make-cmd [prg]
  (fn [arg]
    (if (not prg)
        []
        (let [arg (string.format "'%s'" (or arg ""))
              (cmd n) (string.gsub prg "%$%*" arg)
              cmd (if (= n 0) (.. prg " " arg) cmd)]
          (cmd-callback
            (: (vim.system [vim.o.shell "-c" cmd] {:text true}) :wait))))))

;; Create smart setqflist action: marked items if >1, otherwise all matches
;; Returns a table with action-fn and scheduled-fn for wrapping
(fn utils.make-setqflist [fn-to-qf]
  {:action-fn (fn [self]
                (let [marked (self:getmarked)
                      use-marked (> (length marked) 1)
                      items (if use-marked
                                (-> (vim.iter (ipairs marked))
                                    (: :map (fn [_ id] (. self.items id)))
                                    (: :totable))
                                (-> (vim.iter (ipairs self.matches))
                                    (: :map (fn [_ m] (. self.items (. m 1))))
                                    (: :totable)))]
                  (vim.fn.setqflist
                    (-> (vim.iter (ipairs items))
                        (: :map (fn [_ item] (fn-to-qf item)))
                        (: :totable)))
                  (self:cancel)))
   :scheduled-fn (fn [_] (vim.cmd.copen))})

;; Create file actions (split, vsplit, tabnew)
(fn utils.make-file-actions [fn-to-buf]
  (let [picker-mod (require :picker)
        make-open-action (fn [open-fn]
                           (picker-mod.wrap
                             (fn [self] (self:cancel))
                             (fn [self]
                               (let [item (self:getcurrent)]
                                 (when item
                                   (let [buf (fn-to-buf item)]
                                     (open-fn buf)))))))]
    {:split (make-open-action
              (fn [buf] (vim.api.nvim_open_win buf true {:win -1 :vertical false})))
     :vsplit (make-open-action
               (fn [buf] (vim.api.nvim_open_win buf true {:win -1 :vertical true})))
     :tabnew (make-open-action
               (fn [buf]
                 (vim.api.nvim_cmd
                   {:cmd :split
                    :args [(string.format "+%dbuf" buf)]
                    :mods {:tab 1 :silent true}}
                   {:output false})))}))

utils
