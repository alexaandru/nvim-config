(var mod-cache nil)

(var std-lib nil)

(fn identify-go-dir [custom-args]
  (let [cmd [:go :env custom-args.envvar_id]
        out (vim.fn.system cmd)
        trimmed (vim.trim (or out ""))]
    (if (and (not= trimmed "") (= 0 vim.v.shell_error))
        (if (and custom-args.custom_subdir (not= custom-args.custom_subdir ""))
            (.. trimmed custom-args.custom_subdir)
            trimmed)
        nil)))

;; fnlfmt: skip
(fn get-std-lib-dir []
  (if (and std-lib (not= std-lib ""))
      std-lib
      (do
        (set std-lib (identify-go-dir {:custom_subdir :/src :envvar_id :GOROOT}))
        std-lib)))

;; fnlfmt: skip
(fn get-mod-cache-dir []
  (if (and mod-cache (not= mod-cache ""))
      mod-cache
      (do
        (set mod-cache (identify-go-dir {:envvar_id :GOMODCACHE}))
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

{:cmd [:gopls :-remote=auto :-remote.listen.timeout=8h]
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
