local function n(key, cmd)
  cmd = ("<Cmd>lua vim.lsp.%s()<CR>"):format(cmd)
  vim.api.nvim_buf_set_keymap(0, "n", key, cmd, {noremap = true, silent = true})
end

local function lsp_mappings() -- LuaFormatter off
  n("gd",    "buf.declaration")
  n("<c-]>", "buf.definition")
  n("<F1>",  "buf.hover")
  n("gD",    "buf.implementation")
  n("<c-k>", "buf.signature_help")
  n("1gD",   "buf.type_definition")
  n("gr",    "buf.references")
  n("g0",    "buf.document_symbol")
  n("gW",    "buf.workspace_symbol")
  n("<F2>",  "buf.rename")
  n("<F16>", "buf.code_action")
  n("g[",    "diagnostic.goto_next")
  n("g]",    "diagnostic.goto_prev")
  n("<F7>",  "diagnostic.set_loclist")
end -- LuaFormatter on

local function on_attach_async_fmt(client, bufnr)
  lsp_mappings()
  vim.cmd "au Setup BufWritePre <buffer> lua vim.lsp.buf.formatting()"
end

local function on_attach(client, bufnr)
  lsp_mappings()

  local au = {
    ["OrgImports()"] = client.resolved_capabilities.code_action or nil,
    ["vim.lsp.buf.formatting_sync()"] = client.resolved_capabilities
        .document_formatting or nil,
  }

  if vim.tbl_isempty(au) then return end

  vim.cmd(("au Setup BufWritePre <buffer> lua %s"):format(
              table.concat(vim.tbl_keys(au), "; ")))
end

local efm_cfg = {
  lua = {{formatCommand = "lua-format -i", formatStdin = true}},
  tf = {{formatCommand = "terraform fmt -", formatStdin = true}},
}
local sumneko_root = "/home/alex/.lua_lsp"
local sumneko_binary = sumneko_root .. "/bin/Linux/lua-language-server"
local lsp = require "lspconfig"
local lsp_cfg = {
  bashls = {},
  cssls = {},
  dockerls = {},
  -- https://github.com/tomaskallup/dotfiles/blob/master/nvim/lua/lsp-config.lua,
  -- https://github.com/lukas-reineke/dotfiles/tree/master/vim/lua
  -- https://github.com/tsuyoshicho/vim-efm-langserver-settings
  efm = {
    on_attach = on_attach_async_fmt,
    init_options = {documentFormatting = true},
    filetypes = vim.tbl_keys(efm_cfg),
    settings = {rootMarkers = {".git"}, languages = efm_cfg},
  },
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
  r_language_server = {on_attach = on_attach_async_fmt},
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

for k, v in pairs(lsp_cfg) do
  lsp[k].setup(vim.tbl_extend("keep", v, {on_attach = on_attach}))
end

vim.lsp.handlers["textDocument/publishDiagnostics"] =
    vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
      underline = true,
      virtual_text = {spacing = 5, prefix = "->"},
      signs = false,
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
  textobjects = {
    select = {
      enable = true,
      keymaps = { -- You can use the capture groups defined in textobjects.scm
        af = "@function.outer",
        ["if"] = "@function.inner",
        ac = "@class.outer",
        ic = "@class.inner",
      },
    },
    lsp_interop = {
      enable = true,
      peek_definition_code = {df = "@function.outer", dF = "@class.outer"},
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

-- Synchronously organise imports, courtesy of
-- https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-656372575 and
-- https://github.com/lucax88x/configs/blob/master/dotfiles/.config/nvim/lua/lt/lsp/functions.lua
function OrgImports(ms)
  ms = ms or 1000

  local context = {source = {organizeImports = true}}
  local params = vim.lsp.util.make_range_params()
  params.context = context

  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params,
                                          ms)
  if not result or vim.tbl_isempty(result) then return end

  for _, res in pairs(result) do
    if res.result then
      for _, r in pairs(res.result) do
        if r.edit then
          vim.lsp.util.apply_workspace_edit(r.edit)
        else
          vim.lsp.buf.execute_command(r.command)
        end
      end
    end
  end
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
