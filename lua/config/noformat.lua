return {
  settings = {documentFormatting = false},
  on_attach = function(client, bufnr)
    client.resolved_capabilities.document_formatting = false
    require"lsp".on_attach(client, bufnr)
  end,
}
