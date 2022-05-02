(fn LspCapabilities []
  (vim.notify (vim.inspect (collect [_ c (pairs (vim.lsp.buf_get_clients))]
                             (values c.name
                                     (collect [k v (pairs c.server_capabilities)]
                                       (if v (values k v))))))))

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

{: LspCapabilities : LastWindow : complete}

