(var mod-cache nil)

(var std-lib nil)

(fn identify-go-dir [custom-args on-complete]
  (let [cmd [:go :env custom-args.envvar_id]]
    (vim.system cmd {:text true}
                (fn [output]
                  (var res (vim.trim (or output.stdout "")))
                  (if (and (= output.code 0) (not= res ""))
                      (do
                        (when (and custom-args.custom_subdir
                                   (not= custom-args.custom_subdir ""))
                          (set res (.. res custom-args.custom_subdir)))
                        (on-complete res))
                      (do
                        (vim.schedule #(vim.notify (: (.. "[gopls] identify "
                                                          custom-args.envvar_id
                                                          " dir cmd failed with code %d: %s %s")
                                                      :format output.code
                                                      (vim.inspect cmd)
                                                      output.stderr)))
                        (on-complete nil)))))))

;; fnlfmt: skip
(fn get-std-lib-dir []
  (if (and std-lib (not= std-lib ""))
      std-lib
      (do
        (identify-go-dir {:custom_subdir :/src :envvar_id :GOROOT} #(when $ (set std-lib $)))
        std-lib)))

;; fnlfmt: skip
(fn get-mod-cache-dir []
  (if (and mod-cache (not= mod-cache ""))
      mod-cache
      (do
        (identify-go-dir {:envvar_id :GOMODCACHE} #(when $ (set mod-cache $)))
        mod-cache)))

(fn get-root-dir [fname]
  (or (and mod-cache (= (fname:sub 1 (length mod-cache)) mod-cache)
           (let [clients (vim.lsp.get_clients {:name :gopls})]
             (when (> (length clients) 0)
               (. clients (length clients) :config :root_dir))))
      (and std-lib (= (fname:sub 1 (length std-lib)) std-lib)
           (let [clients (vim.lsp.get_clients {:name :gopls})]
             (when (> (length clients) 0)
               (. clients (length clients) :config :root_dir))))
      (vim.fs.root fname "go.work") (vim.fs.root fname "go.mod")
      (vim.fs.root fname ".git")))

{:cmd [:gopls :-remote=auto]
 :filetypes [:go :gomod :gowork :gotmpl :template]
 :root_dir (fn [bufnr on-dir]
             (let [fname (vim.api.nvim_buf_get_name bufnr)]
               (get-mod-cache-dir)
               (get-std-lib-dir)
               (on-dir (get-root-dir fname))))
 :single_file_support true
 :settings {:gopls {:vulncheck :Imports
                    :analyses {;; https://github.com/golang/tools/blob/master/gopls/doc/analyzers.md
                               :appendclipped true
                               :shadow true
                               :slicesdelete true}
                    :buildFlags [:-tags=test]
                    :directoryFilters [:-**/node_modules :-**/testdata]
                    :templateExtensions [:tmpl]
                    :codelenses {:gc_details true :test true :vulncheck true}
                    :staticcheck true
                    :gofumpt false
                    :hoverKind :FullDocumentation
                    ;; :SynopsisDocumentation
                    ; https://github.com/golang/tools/blob/master/gopls/doc/inlayHints.md
                    :experimentalPostfixCompletions true
                    :semanticTokens true
                    :usePlaceholders false
                    :local vim.env.GOPRIVATE}}}
