{:settings {:documentFormatting false}
 :on_attach (fn [client bufnr]
              (set client.resolved_capabilities.document_formatting false)
              ((. (require :lsp) :on_attach) client bufnr))}

