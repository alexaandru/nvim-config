local function nno(key, cmd)
  cmd = ("<Cmd>lua vim.lsp.%s()<CR>"):format(cmd)
  vim.api.nvim_buf_set_keymap(0, "n", key, cmd, {noremap = true, silent = true})
end

local lsp_keys = { -- LuaFormatter off
  ["buf.declaration"]        = "gd",
  ["buf.definition"]         = "<c-]>",
  ["buf.hover"]              = "<F1>",
  ["buf.implementation"]     = "gD",
  ["buf.signature_help"]     = "<c-k>",
  ["buf.type_definition"]    = "1gD",
  ["buf.references"]         = "gr",
  ["buf.document_symbol"]    = "g0",
  ["buf.workspace_symbol"]   = "gW",
  ["buf.rename"]             = "<F2>",
  ["buf.code_action"]        = "<F16>",
  ["diagnostic.goto_next"]   = "g[",
  ["diagnostic.goto_prev"]   = "g]",
  ["diagnostic.set_loclist"] = "<F7>",
} -- LuaFormatter on

local function on_attach_async_fmt(client, bufnr)
  for cmd, key in pairs(lsp_keys) do nno(key, cmd) end
  vim.cmd "au Setup BufWritePre <buffer> lua vim.lsp.buf.formatting()"
end

local function on_attach(client, bufnr)
  for cmd, key in pairs(lsp_keys) do nno(key, cmd) end

  local au = {
    ["OrgImports()"] = client.resolved_capabilities.code_action or nil,
    ["vim.lsp.buf.formatting_sync()"] = client.resolved_capabilities
        .document_formatting or nil,
  }

  if vim.tbl_isempty(au) then return end

  vim.cmd(("au Setup BufWritePre <buffer> lua %s"):format(
              table.concat(vim.tbl_keys(au), "; ")))
end

local prettier = {
  formatCommand = "npx prettier --arrow-parens avoid --stdin-filepath ${INPUT}",
  formatStdin = true,
}
local eslint = { -- WIP
  lintCommand = "npx eslint -f compact --stdin-filename ${INPUT}",
  lintStdin = true,
  lintIgnoreExitCode = true,
  lintFormats = {
    "%f: line %l, col %c, %trror - %m",
    "%f: line %l, col %c, %tarning - %m",
  },
}
local efm_cfg = {
  lua = {{formatCommand = "lua-format -i", formatStdin = true}},
  tf = {{formatCommand = "terraform fmt -", formatStdin = true}},
  json = {{formatCommand = "jq .", formatStdin = true}},
  javascript = {prettier},
  typescript = {prettier},
  yaml = {prettier},
  vue = {prettier},
  html = {prettier},
  scss = {prettier},
  css = {prettier},
  markdown = {prettier},
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
    init_options = {documentFormatting = true, codeAction = true},
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
  tsserver = {
    on_attach = function(client, bufnr)
      -- prefer prettier
      client.resolved_capabilities.document_formatting = false
      on_attach(client, bufnr)
    end,
    settings = {documentFormatting = false},
  },
  vimls = {},
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
  local _, c = next(vim.lsp.buf_get_clients())
  print(vim.inspect(c.resolved_capabilities))
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
  for _, res in pairs(result or {}) do
    for _, r in pairs(res.result or {}) do
      if r.edit then
        vim.lsp.util.apply_workspace_edit(r.edit)
      else
        vim.lsp.buf.execute_command(r.command)
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
