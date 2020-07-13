-- LSP
require'nvim_lsp'.bashls.setup{}
require'nvim_lsp'.cssls.setup{}
require'nvim_lsp'.dockerls.setup{}
require'nvim_lsp'.gopls.setup{}
require'nvim_lsp'.html.setup{}
require'nvim_lsp'.jsonls.setup{}
require'nvim_lsp'.sumneko_lua.setup{}
require'nvim_lsp'.terraformls.setup{}
require'nvim_lsp'.tsserver.setup{}
require'nvim_lsp'.vimls.setup{}
require'nvim_lsp'.vuels.setup{}

-- Synchronously organise (Go) imports.
function go_org_imports(timeout_ms)
  local context = { source = { organizeImports = true } }
  vim.validate { context = { context, 't', true } }
  local params = vim.lsp.util.make_range_params()
  params.context = context

  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, timeout_ms)
  if not result then return end
  result = result[1].result
  if not result then return end
  edit = result[1].edit
  vim.lsp.util.apply_workspace_edit(edit)
end

vim.api.nvim_command("au BufWritePre *.go lua go_org_imports(500)")
vim.api.nvim_command("au BufWritePre *.go lua vim.lsp.buf.formatting_sync()")
