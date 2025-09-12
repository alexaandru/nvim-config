(var fnames [])
(var handle nil)

;; fnlfmt: skip
(fn refresh []
  (when (and (= handle nil) (= (length fnames) 0))
    (set fnames [])
    (var prev nil)
    (set handle (vim.system [:fd :-t :f :--hidden :--color=never :--max-depth 10]
                            {:stdout (fn [err data]
                                       (assert (not err) err)
                                       (when data
                                         (local full-data (if prev (.. prev data) data))
                                         (if (= (string.sub full-data -1) "\n")
                                             (do
                                               (vim.list_extend fnames (vim.split full-data "\n" {:trimempty true}))
                                               (set prev nil))
                                             (do
                                               (local parts (vim.split full-data "\n" {:trimempty true}))
                                               (when (> (length parts) 1)
                                                 (set prev (. parts (length parts)))
                                                 (tset parts (length parts) nil)
                                                 (vim.list_extend fnames parts))
                                               (when (= (length parts) 1)
                                                 (set prev (. parts 1)))))))}
                            (fn [obj]
                              (when (not= obj.code 0) (print "Command failed"))
                              (set handle nil))))
    (vim.api.nvim_create_autocmd :CmdlineLeave
                                 {:callback #(when handle (handle:wait 0) (set handle nil))
                                  :once true})))

(fn findfunc [cmdarg _cmdcomplete]
  (when (= (length fnames) 0)
    (refresh)
    (vim.wait 200 (fn [] (> (length fnames) 0))))
  (if (= (length cmdarg) 0)
      fnames
      (vim.fn.matchfuzzy fnames cmdarg {:limit 30 :matchseq 1 :key "tail"})))

;; Force refresh command
(vim.api.nvim_create_user_command :FindRefresh
                                  (fn []
                                    (set fnames [])
                                    (when handle
                                      (handle:wait 0)
                                      (set handle nil))
                                    (print "File cache refreshed"))
                                  {:desc "Force refresh file finder cache"})

(when (= (vim.fn.executable :fd) 1)
  (fn _G.Fd_findfunc [cmdarg _cmdcomplete]
    (findfunc cmdarg _cmdcomplete))

  (set vim.o.findfunc "v:lua.Fd_findfunc"))
