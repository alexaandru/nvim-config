{:before_init (fn [_ config]
                (var (v1 v2) (values false false))
                (when (= (vim.fn.executable :go) 1)
                  (local exe (vim.fn.exepath :golangci-lint))
                  (local version (: (vim.system [:go :version :-m exe]) :wait))
                  (set v1
                       (string.match version.stdout
                                     "\tmod\tgithub.com/golangci/golangci%-lint\t"))
                  (set v2
                       (string.match version.stdout
                                     "\tmod\tgithub.com/golangci/golangci%-lint/v2\t")))
                (when (and (not v1) (not v2))
                  (local version (: (vim.system [:golangci-lint :version])
                                    :wait))
                  (set v1 (string.match version.stdout "version v?1%.")))
                (when v1
                  (set config.init_options.command
                       [:golangci-lint :run :--out-format :json])))
 :cmd [:golangci-lint-langserver]
 :filetypes [:go :gomod]
 :init_options {:command [:golangci-lint
                          :run
                          :--output.json.path=stdout
                          :--show-stats=false
                          :--issues-exit-code=1]}
 :root_markers [:.golangci.yml
                :.golangci.yaml
                :.golangci.toml
                :.golangci.json
                :go.work
                :go.mod
                :.git]}
