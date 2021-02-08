local sumneko_root = "/home/alex/.lua_lsp"
local sumneko_binary = sumneko_root .. "/bin/Linux/lua-language-server"
local lsp = require "lspconfig"
local lsp_cfg = {
  bashls = {},
  cssls = {},
  dockerls = {},
  gopls = { -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
    cmd = {"gopls", "serve"},
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
        hoverKind = "SynopsisDocumentation",
      },
    },
  },
  html = {},
  jsonls = {},
  pyls = {},
  r_language_server = nil,
  sumneko_lua = { -- https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json
    cmd = {sumneko_binary, "-E", sumneko_root .. "/main.lua"},
    settings = {
      Lua = {
        runtime = {version = "LuaJIT", path = vim.split(package.path, ";")},
        diagnostics = {globals = {"vim"}},
        workspace = {
          library = {
            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
            [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
          },
        },
      },
    },
  },
  terraformls = {},
  tsserver = {},
  vimls = {},
  vls = nil, -- {cmd = {"/usr/local/bin/vls"}},
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

require"nvim-treesitter.configs".setup {
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
  ensure_installed = "all",
}

vim.cmd("set termguicolors")
require"colorizer".setup()

function LspCapabilities()
  local _, v = next(vim.lsp.buf_get_clients())
  print(vim.inspect(v.server_capabilities))
end

-- Synchronously organise (Go) imports, courtesy of
-- https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-656372575
-- NOTE: this is NOT Go specific,
-- and also not complete, it could return either edits or commands,
-- see https://github.com/lucax88x/configs/blob/master/dotfiles/.config/nvim/lua/lt/lsp/functions.lua
function GoOrgImports(timeout_ms)
  timeout_ms = timeout_ms or 1000

  local context = {source = {organizeImports = true}}
  local params = vim.lsp.util.make_range_params()
  params.context = context

  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params,
                                          timeout_ms)
  if not result or not result[1] then return end

  result = result[1].result
  if not result then return end

  local edit = result[1].edit
  vim.lsp.util.apply_workspace_edit(edit)
end

-- inspired by https://vim.fandom.com/wiki/Smart_mapping_for_tab_completion
function SmartTabComplete()
  local s = vim.fn.getline("."):sub(1, vim.fn.col(".") - 1):gsub("%s+", "")

  if s == "" then return "	" end
  if s:sub(s:len(), s:len()) == "/" then return "" end
  return ""
end

local tsu = require "nvim-treesitter.ts_utils"
-- experiment: get current function name when on function name or inside ()
-- use that to query LSP about function signature
-- then what??? how/when to display it? where?
-- see https://github.com/neovim/neovim/issues/12390#issuecomment-716107137
function CurrNode(winnr, bufnr)
  local node = tsu.get_node_at_cursor(winnr or 0)
  local text = tsu.get_node_text(node, bufnr or 0)
  print("Current node: " .. vim.inspect(text))
end
