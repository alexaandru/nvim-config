(fn LspCapabilities []
  (vim.notify (vim.inspect (collect [_ c (pairs (vim.lsp.buf_get_clients))]
                             c.name
                             (collect [k v (pairs c.server_capabilities)]
                               (if v (values k v)))))))

(local cfg-files ;;
       (let [c (vim.fn.stdpath :config)
             glob #(vim.fn.glob (.. c "/" $) 0 1)
             files (glob :fnl/**/*.fnl)
             rm-prefix #($:sub (+ 6 (length c)))]
         (vim.tbl_map rm-prefix files)))

(fn complete [arg-lead]
  (vim.tbl_filter #(or (= arg-lead "") ($:find arg-lead)) cfg-files))

(fn is-quittable []
  (let [{:buftype bt :filetype ft} (vim.fn.getbufvar "%" "&")]
    (or (vim.tbl_contains [:quickfix :terminal :nofile] bt) (= ft :netrw))))

(fn last-window []
  (= -1 (vim.fn.winbufnr 2)))

(fn LastWindow []
  (if (and (is-quittable) (last-window))
      (vim.cmd "norm ZQ")))

;; https://github.com/neovim/neovim/pull/13896
(fn get-range []
  ;; https://github.com/neovim/neovim/pull/13896#issuecomment-774680224
  (var [_ l1] (vim.fn.getpos :v))
  (var [_ l2] (vim.fn.getcurpos))
  (when (= l1 l2)
    (set l1 1)
    (set l2 (vim.fn.line "$")))
  (when (> l1 l2)
    (local tmp l1)
    (set l1 l2)
    (set l2 tmp))
  [l1 l2])

(fn get-selection []
  (let [[l1 l2] (get-range)
        lines (vim.fn.getline l1 l2)
        text (table.concat lines "\n")]
    text))

{: LspCapabilities : LastWindow : complete : get-range : get-selection}

