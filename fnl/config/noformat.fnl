{:settings {:documentFormatting false}
 :on_attach (fn [client bufnr]
              (set client.server_capabilities.documentFormattingProvider false)
              ((. (require :lsp) :on_attach) client bufnr))}

