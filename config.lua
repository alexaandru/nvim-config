if vim.g.lua_loaded then
  do return end
end; vim.g.lua_loaded = 1

require'lspconfig'.bashls.setup{}
require'lspconfig'.cssls.setup{}
require'lspconfig'.dockerls.setup{}
require'lspconfig'.gopls.setup{
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
require'lspconfig'.html.setup{}
require'lspconfig'.jsonls.setup{}
-- require'lspconfig'.pyls_ms.setup{}
require'lspconfig'.pyls.setup{}
require'lspconfig'.sumneko_lua.setup{
  -- see https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json
  -- for more settings
  settings = {Lua = {diagnostics = {globals = {"vim"}}}}
}
require'lspconfig'.terraformls.setup{}
require'lspconfig'.tsserver.setup{}
require'lspconfig'.vimls.setup{}
require'lspconfig'.vuels.setup{}
require'lspconfig'.yamlls.setup{}

-- local lsputilConfig = {
  -- ['textDocument/codeAction']     = require'lsputil.codeAction'.code_action_handler,
  -- ['textDocument/references']     = require'lsputil.locations'.references_handler,
  -- ['textDocument/definition']     = require'lsputil.locations'.definition_handler,
  -- ['textDocument/declaration']    = require'lsputil.locations'.declaration_handler,
  -- ['textDocument/typeDefinition'] = require'lsputil.locations'.typeDefinition_handler,
  -- ['textDocument/implementation'] = require'lsputil.locations'.implementation_handler,
  -- ['textDocument/documentSymbol'] = require'lsputil.symbols'.document_handler,
  -- ['workspace/symbol']            = require'lsputil.symbols'.workspace_handler,
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
-- https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-656372575
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
