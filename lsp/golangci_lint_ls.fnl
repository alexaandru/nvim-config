(fn before_init [_ cfg]
  (let [root (or cfg.root_dir (vim.fn.getcwd))
        tools-go-mod (.. root "/tools/go.mod")]
    (if (= (vim.fn.filereadable tools-go-mod) 1)
        (let [cmd cfg.init_options.command]
          (set cfg.init_options.command
               (vim.list_extend [:go :tool (.. "-modfile=" tools-go-mod)] cmd))))))

{: before_init
 :cmd [:golangci-lint-langserver]
 :filetypes [:go :gomod]
 :init_options {:command [:golangci-lint :run :--output.json.path=stdout :--show-stats=false :--issues-exit-code=1]}
 :root_markers [:.golangci.yml :.golangci.yaml :go.mod :.git]}
