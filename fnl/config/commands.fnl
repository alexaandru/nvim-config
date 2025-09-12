(fn LspCapabilities []
  (vim.notify (vim.inspect (collect [_ c (pairs (vim.lsp.get_clients {:buffer 0}))]
                             c.name (collect [k v (pairs c.server_capabilities)]
                               (if v (values k v)))))))

(fn LastWindow []
  (fn is-quittable []
    (let [{:buftype bt :filetype ft} (vim.fn.getbufvar "%" "&")]
      (or (vim.tbl_contains [:quickfix :terminal :nofile] bt) (= ft :netrw))))

  (fn last-window []
    (= -1 (vim.fn.winbufnr 2)))

  (if (and (is-quittable) (last-window))
      (vim.cmd "norm ZQ")))

(fn LspHintsToggle []
  (when vim.b.hints_on
    (if (not vim.b.hints) (set vim.b.hints (vim.lsp.inlay_hint.is_enabled)))
    (set vim.b.hints (not vim.b.hints))
    (vim.lsp.inlay_hint.enable vim.b.hints {:bufnr 0})))

(fn SetProjRoot []
  (let [pat (vim.fn.expand "%:p:h")
        pat (.. pat ";")
        dir (vim.fn.finddir ".git/.." pat)
        root (vim.fn.fnamemodify dir ":p")]
    (set vim.w.proj_root root)))

(fn BuiltinPacks []
  (let [result []
        all (vim.fn.globpath vim.o.packpath "pack/*/opt/*" true true)]
    (each [_ path (ipairs all)]
      (when (path:match "^/tmp/%.mount_nvim")
        (table.insert result (vim.fs.basename path))))
    (print (vim.inspect result))))

{: LspCapabilities : LastWindow : LspHintsToggle : SetProjRoot : BuiltinPacks}
