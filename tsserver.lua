return {
  on_attach = function(client, bufnr)
    -- prefer prettier
    client.resolved_capabilities.document_formatting = false
    require"lsp".on_attach(client, bufnr)
  end,
  settings = {documentFormatting = false},
}
