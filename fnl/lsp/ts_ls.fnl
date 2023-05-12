;https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/tsserver.lua
;https://openbase.com/js/typescript-language-server/documentation
;https://github.com/microsoft/TypeScript/blob/main/src/compiler/diagnosticMessages.json
(local block-list [2339 2531 7043 7044 7045 7046 7047 7048 7049 7050])

;https://neovim.io/doc/user/lsp.html#lsp-handler
(fn err-filter [err result ctx config]
  (if (= vim.bo.filetype :javascript)
      (set result.diagnostics
           (icollect [_ v (ipairs result.diagnostics)]
             (let [allow-code (not (vim.tbl_contains block-list v.code))]
               (if allow-code v)))))
  (vim.lsp.diagnostic.on_publish_diagnostics err result ctx config))

;; fnlfmt: skip
(local inlayHints {:includeInlayEnumMemberValueHints true
                   :includeInlayFunctionLikeReturnTypeHints true
                   :includeInlayFunctionParameterTypeHints true
                   :includeInlayParameterNameHints :all ;; none | literals | all
                   :includeInlayParameterNameHintsWhenArgumentMatchesName true
                   :includeInlayPropertyDeclarationTypeHints true
                   :includeInlayVariableTypeHints true})

{:cmd [:typescript-language-server :--stdio]
 :commands {:editor.action.showReferences (fn [command ctx]
                                            (local client
                                                   (assert (vim.lsp.get_client_by_id ctx.client_id)))
                                            (local (file-uri position
                                                             references)
                                                   (unpack command.arguments))
                                            (local quickfix-items
                                                   (vim.lsp.util.locations_to_items references
                                                                                    client.offset_encoding))
                                            (vim.fn.setqflist {} " "
                                                              {:context {:bufnr ctx.bufnr
                                                                         : command}
                                                               :items quickfix-items
                                                               :title command.title})
                                            (vim.lsp.util.show_document {:range {:end position
                                                                                 :start position}
                                                                         :uri file-uri}
                                                                        client.offset_encoding)
                                            (vim.cmd "botright copen"))}
 :filetypes [:javascript
             :javascriptreact
             :javascript.jsx
             :typescript
             :typescriptreact
             :typescript.tsx
             :vue]
 :handlers {:_typescript.rename (fn [_ result ctx]
                                  (local client
                                         (assert (vim.lsp.get_client_by_id ctx.client_id)))
                                  (vim.lsp.util.show_document {:range {:end result.position
                                                                       :start result.position}
                                                               :uri result.textDocument.uri}
                                                              client.offset_encoding)
                                  (vim.lsp.buf.rename)
                                  vim.NIL)
            :textDocument/publishDiagnostics err-filter}
 :init_options {:hostInfo :neovim
                :plugins [{:name "@vue/typescript-plugin"
                           :location "/home/alex/.nvm/versions/node/v22.12.0/lib/node_modules/@vue/typescript-plugin"
                           :languages [:javascript :typescript :vue]}]}
 :on_attach (fn [client bufnr]
              (vim.api.nvim_buf_create_user_command bufnr
                                                    :LspTypescriptSourceAction
                                                    (fn []
                                                      (local source-actions
                                                             (vim.tbl_filter (fn [action]
                                                                               (vim.startswith action
                                                                                               :source.))
                                                                             client.server_capabilities.codeActionProvider.codeActionKinds))
                                                      (vim.lsp.buf.code_action {:context {:only source-actions}}))
                                                    {}))
 :root_dir (fn [bufnr on-dir]
             (var root-markers [:package-lock.json
                                :yarn.lock
                                :pnpm-lock.yaml
                                :bun.lockb
                                :bun.lock
                                :deno.lock])
             (set root-markers (or (and (= (vim.fn.has :nvim-0.11.3) 1)
                                        [root-markers])
                                   root-markers))
             (local project-root (vim.fs.root bufnr root-markers))
             (when (not project-root) (lua "return "))
             (on-dir project-root))
 :settings {:documentFormatting false
            :implicitProjectConfiguration {:checkJs true}
            :typescript {: inlayHints}
            :javascript {: inlayHints}}}
