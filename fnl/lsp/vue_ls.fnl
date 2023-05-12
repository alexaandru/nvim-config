{:cmd [:vue-language-server :--stdio]
 :filetypes [:vue]
 :on_init (fn [client]
            (var retries 0)

            (fn typescript-handler [_ result context]
              (local ts-client (or (. (vim.lsp.get_clients {:bufnr context.bufnr
                                                            :name "ts_ls"})
                                      1)
                                   (. (vim.lsp.get_clients {:bufnr context.bufnr
                                                            :name "vtsls"})
                                      1)
                                   (. (vim.lsp.get_clients {:bufnr context.bufnr
                                                            :name "typescript-tools"})
                                      1)))
              (when (not ts-client)
                (if (<= retries 10)
                    (do
                      (set retries (+ retries 1))
                      (vim.defer_fn #(typescript-handler _ result context)
                        100))
                    (vim.notify "Could not find `ts_ls`, `vtsls`, or `typescript-tools` lsp client required by `vue_ls`."
                                vim.log.levels.ERROR))
                (lua "return "))
              (local param (unpack result))
              (local (id command payload) (unpack param))
              (ts-client:exec_cmd {:arguments [command payload]
                                   :command :typescript.tsserverRequest
                                   :title :vue_request_forward}
                                  {:bufnr context.bufnr}
                                  (fn [_ r]
                                    (local response-data [[id (and r r.body)]])
                                    (client:notify :tsserver/response
                                                   response-data))))

            (set client.handlers.tsserver/request typescript-handler))
 :root_markers [:package.json]
 :init_options {:typescript {:tsdk "/home/alex/.nvm/versions/node/v22.12.0/lib/node_modules/typescript/lib"}
                :preferences {:disableSuggestions true}
                :languageFeatures {:implementation true
                                   :references true
                                   :definition true
                                   :typeDefinition true
                                   :callHierarchy true
                                   :hover true
                                   :rename true
                                   :renameFileRefactoring true
                                   :signatureHelp true
                                   :codeAction true
                                   :workspaceSymbol true
                                   :diagnostics true
                                   :semanticTokens true
                                   :completion {:defaultTagNameCase :both
                                                :defaultAttrNameCase :kebabCase
                                                :getDocumentNameCasesRequest false
                                                :getDocumentSelectionRequest false}}}}
