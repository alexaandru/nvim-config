(local noformat
       {:settings {:documentFormatting false}
        :on_attach (fn [client bufnr]
                     (set client.server_capabilities.documentFormattingProvider
                          false)
                     ((. (require :lsp) :on_attach) client bufnr))})

; https://github.com/hashicorp/terraform-ls/blob/main/docs/SETTINGS.md
(local terraformls
       {:filetypes [:terraform :tf :hcl]
        :init_options {:experimentalFeatures {:validateOnSave true}}})

;https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/server_configurations/tsserver.lua
;https://openbase.com/js/typescript-language-server/documentation
;https://github.com/microsoft/TypeScript/blob/main/src/compiler/diagnosticMessages.json
(local block-list [2339 7043 7044 7045 7046 7047 7048 7049 7050])

;https://neovim.io/doc/user/lsp.html#lsp-handler
(fn err-filter [err result ctx config]
  (if (= vim.bo.filetype :javascript)
      (set result.diagnostics
           (icollect [_ v (ipairs result.diagnostics)]
             (let [allow-code (not (vim.tbl_contains block-list v.code))]
               (if allow-code v)))))
  (vim.lsp.diagnostic.on_publish_diagnostics err result ctx config))

;; fnlfmt: skip
(local tsserver (vim.tbl_extend :error noformat
       {:handlers {:textDocument/publishDiagnostics err-filter}}))

(local lsp vim.lsp.buf)

{:bashls {}
 :cssls {}
 :dockerls {}
 :efm (require :config.efm)
 :gopls (require :config.gopls)
 :html noformat
 :jsonls noformat
 :pylsp {}
 : terraformls
 :tflint {}
 : tsserver
 :vuels {}
 :yamlls {}
 :__diag {:underline true
          :virtual_text {:spacing 1 :prefix "📌"}
          :signs true
          :update_in_insert true
          :severity_sort true}
 :__keys {:gd lsp.declaration
          "<c-]>" lsp.definition
          :<F1> lsp.hover
          :gD lsp.implementation
          :<c-k> lsp.signature_help
          :1gD lsp.type_definition
          :gr lsp.references
          :g0 lsp.document_symbol
          :gW lsp.workspace_symbol
          :<F2> lsp.rename
          :<F16> lsp.code_action
          :<M-Right> vim.diagnostic.goto_next
          :<M-Left> vim.diagnostic.goto_prev
          :<F7> vim.diagnostic.setloclist
          :<Leader>k vim.lsp.codelens.run}}

