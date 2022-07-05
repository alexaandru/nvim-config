;; https://github.com/golang/tools/blob/master/gopls/doc/settings.md
{:filetypes [:go :gomod :template]
 :settings {:gopls {:analyses {:fieldalignment true
                               :nilness true
                               :shadow true
                               :unusedparams true
                               :unusedwrite true
                               :useany true}
                    :buildFlags [:-tags=development]
                    :directoryFilters nil
                    :templateExtensions [:tmpl]
                    :codelenses {:gc_details true}
                    :staticcheck true
                    :gofumpt true
                    ;; :SynopsisDocumentation
                    :hoverKind :FullDocumentation
                    ; https://github.com/golang/tools/blob/master/gopls/doc/inlayHints.md
                    ; TODO https://github.com/neovim/neovim/issues/18086
                    :hints {:assignVariableTypes true
                            :compositeLiteralFields true
                            :compositeLiteralTypes true
                            :constantValues true
                            :functionTypeParameters true
                            :parameterNames true
                            :rangeVariableTypes true}
                    :experimentalWorkspaceModule true
                    :experimentalPostfixCompletions true
                    :semanticTokens true
                    :usePlaceholders true}}}

