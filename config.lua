local sumneko_root = '/home/alex/.lua_lsp'
local sumneko_binary = sumneko_root .. '/bin/Linux/lua-language-server'
local lsp = require 'lspconfig'
local lsp_cfg = {
  bashls = {},
  cssls = {},
  dockerls = {},
  gopls = { -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
    cmd = {'gopls', 'serve'},
    settings = {
      gopls = {
        analyses = {fieldalignment = true, shadow = true, unusedparams = true},
        codelenses = {
          gc_details = true,
          test = true,
          generate = true,
          tidy = true,
        },
        staticcheck = true,
        gofumpt = true,
        hoverKind = 'SynopsisDocumentation',
      },
    },
  },
  html = {},
  jsonls = {},
  pyls = {},
  sumneko_lua = { -- https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json
    cmd = {sumneko_binary, '-E', sumneko_root .. '/main.lua'},
    settings = {
      Lua = {
        runtime = {version = 'LuaJIT', path = vim.split(package.path, ';')},
        diagnostics = {globals = {'vim'}},
        workspace = {
          library = {
            [vim.fn.expand('$VIMRUNTIME/lua')] = true,
            [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
          },
        },
      },
    },
  },
  terraformls = {},
  tsserver = {},
  vimls = {},
  vuels = {},
  yamlls = {},
}

for k, v in pairs(lsp_cfg) do lsp[k].setup(v) end

vim.lsp.handlers["textDocument/publishDiagnostics"] =
    vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
      underline = true,
      virtual_text = true,
      signs = true,
      update_in_insert = true,
    })

require'nvim-treesitter.configs'.setup {
  highlight = {enable = true},
  indent = {enable = true},
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<Return>",
      node_incremental = "<Return>",
      scope_incremental = "<Tab>",
      node_decremental = "<S-Tab>",
    },
  },
  ensure_installed = 'all',
}

require'compe'.setup {
  enabled = true,
  min_length = 2,
  preselect = 'enable', -- 'disable' | 'always'
  source = {path = true, buffer = true, nvim_lsp = true},
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

  local context = {source = {organizeImports = true}}
  local params = vim.lsp.util.make_range_params()
  params.context = context

  local result = vim.lsp.buf_request_sync(0, 'textDocument/codeAction', params,
                                          timeout_ms)
  if not result or not result[1] then return end

  result = result[1].result
  if not result then return end

  local edit = result[1].edit
  vim.lsp.util.apply_workspace_edit(edit)
end
