if vim.g.lua_loaded then
  do return end
end; vim.g.lua_loaded = 1

require'nvim_lsp'.bashls.setup{}
require'nvim_lsp'.cssls.setup{}
require'nvim_lsp'.dockerls.setup{}
require'nvim_lsp'.gopls.setup{
  -- on_attach = require'diagnostic'.on_attach,
  cmd = {"gopls", "serve"},
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
      },
      codelens = {
        gc_details = true,
        test = true,
      },
      staticcheck = true,
    },
  },
}
require'nvim_lsp'.html.setup{}
require'nvim_lsp'.jsonls.setup{}
-- require'nvim_lsp'.pyls_ms.setup{}
require'nvim_lsp'.pyls.setup{}
require'nvim_lsp'.sumneko_lua.setup{
  -- see https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json
  -- for more settings
  settings = {Lua = {diagnostics = {globals = {"vim"}}}}
}
require'nvim_lsp'.terraformls.setup{
  cmd = {'terraform-ls', 'serve'}
}
require'nvim_lsp'.tsserver.setup{}
require'nvim_lsp'.vimls.setup{}
require'nvim_lsp'.vuels.setup{}
require'nvim_lsp'.yamlls.setup{}

-- local lsputilConfig = {
--   ['textDocument/codeAction']     = require'lsputil.codeAction'.code_action_handler,
--   ['textDocument/references']     = require'lsputil.locations'.references_handler,
--   ['textDocument/definition']     = require'lsputil.locations'.definition_handler,
--   ['textDocument/declaration']    = require'lsputil.locations'.declaration_handler,
--   ['textDocument/typeDefinition'] = require'lsputil.locations'.typeDefinition_handler,
--   ['textDocument/implementation'] = require'lsputil.locations'.implementation_handler,
--   ['textDocument/documentSymbol'] = require'lsputil.symbols'.document_handler,
--   ['workspace/symbol']            = require'lsputil.symbols'.workspace_handler,
-- }; for k,v in pairs(lsputilConfig) do vim.lsp.callbacks[k] = v end

require'nvim-treesitter.configs'.setup{
  highlight = {enable = true},
  ensure_installed = {'go', 'json', 'lua', 'html', 'css', 'markdown', 'vue', 'python'}
}

vim.cmd('set termguicolors')
require'colorizer'.setup()

function LspCapabilities()
  local _, v = next(vim.lsp.buf_get_clients())
  print(vim.inspect(v.server_capabilities))
end

-- Synchronously organise (Go) imports, courtesy of
-- https://github.com/neovim/nvim-lsp/issues/115#issuecomment-656372575
function GoOrgImports(timeout_ms)
  timeout_ms = timeout_ms or 1000

  local context = {source={organizeImports=true}}
  vim.validate {context={context, 't', true}}

  local params = vim.lsp.util.make_range_params()
  params.context = context

  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, timeout_ms)
  if not result or not result[1] then return end

  result = result[1].result
  if not result then return end

  local edit = result[1].edit
  vim.lsp.util.apply_workspace_edit(edit)
end
