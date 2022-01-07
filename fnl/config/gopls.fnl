;; https://github.com/golang/tools/blob/master/gopls/doc/settings.md

{:filetypes [:go :gomod :template]
 :settings {:gopls {:analyses {:fieldalignment true
                               :nilness true
                               :shadow true
                               :unusedparams true
                               :unusedwrite true}
                    :codelenses {:gc_details true}
                    :staticcheck true
                    :gofumpt true
                    :hoverKind :SynopsisDocumentation
                    :experimentalWorkspaceModule true
                    :semanticTokens true}}}

