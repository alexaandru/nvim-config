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
  (let [after (?. event.data.spec.data :after)]
    (if after
        (let [pkg-name event.data.spec.name
              wait-for-pkg (fn wait []
                             (tset package.loaded pkg-name nil)
                             (let [(ok _) (pcall require pkg-name)]
                               (if ok
                                   (if (= (type after) :string) (vim.cmd after)
                                       (= (type after) :function) (after)
                                       nil)
                                   (vim.defer_fn wait 50))))]
          (wait-for-pkg))))
  false)

{: LoadLocalCfg : ReColor : LspHintsToggle : PackChanged}
