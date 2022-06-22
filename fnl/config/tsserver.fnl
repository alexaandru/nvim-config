;https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/tsserver.lua
;https://openbase.com/js/typescript-language-server/documentation

;https://github.com/microsoft/TypeScript/blob/main/src/compiler/diagnosticMessages.json
(local block-list [2339])

;https://neovim.io/doc/user/lsp.html#lsp-handler
(fn filter [err result ctx config]
  (if (= vim.bo.filetype :javascript)
      (set result.diagnostics
           (icollect [_ v (ipairs result.diagnostics)]
             (let [allow-code (not (vim.tbl_contains block-list v.code))]
               (if allow-code v)))))
  (vim.lsp.diagnostic.on_publish_diagnostics err result ctx config))

(vim.tbl_extend :error (require :config.noformat)
                {:handlers {:textDocument/publishDiagnostics filter}})

