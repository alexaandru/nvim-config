(fn LoadLocalCfg []
  (if (= 1 (vim.fn.filereadable :.nvimrc))
      (vim.cmd "so .nvimrc")))

(fn ReColor []
  (let [name (.. :froggy.colors. vim.g.colors_name)]
    (tset package.loaded name nil)
    ((require :froggy) (require name)))
  (vim.cmd :redr!))

(fn LspHintsToggle [val]
  (if vim.b.hints_on (vim.lsp.inlay_hint.enable val {:bufnr 0})))

(fn PackChanged [event]
  (print (vim.inspect event)))

{: LoadLocalCfg : ReColor : LspHintsToggle : PackChanged}
