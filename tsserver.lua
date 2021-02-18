return {
  on_attach = function(client, bufnr)
    -- prefer prettier
    client.resolved_capabilities.document_formatting = false
    require"util".on_attacher()(client, bufnr)
  end,
  settings = {documentFormatting = false},
}
