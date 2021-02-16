local async = true

local keys_cfg = { -- LuaFormatter off
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

local function fmtCmd(cmd)
  return {formatCommand = cmd, formatStdin = true}
end

local function lintCmd(cmd, fmt)
  fmt = fmt or "%f:%l:%c: %m"
  return {lintCommand = cmd, lintStdin = true, lintFormats = {fmt}}
end

local prettier = fmtCmd(
                     "npx prettier --arrow-parens avoid --stdin-filepath ${INPUT}")

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
  lua = {
    fmtCmd("lua-format -i"),
    lintCmd("luacheck --formatter plain --globals vim -- ${INPUT}"),
  },
  tf = {fmtCmd("terraform fmt -"), lintCmd("tflint ${INPUT}")},
  json = {fmtCmd("jq ."), lintCmd("jsonlint ${INPUT}")},
  javascript = {prettier},
  typescript = {prettier},
  yaml = {prettier},
  vue = {prettier},
  html = {prettier},
  scss = {prettier},
  css = {prettier},
  markdown = {prettier},
  vim = {lintCmd("vint --enable-neovim ${INPUT}")},
}

local function nno(key, cmd)
  cmd = ("<Cmd>lua vim.lsp.%s()<CR>"):format(cmd)
  vim.api.nvim_buf_set_keymap(0, "n", key, cmd, {noremap = true, silent = true})
end

local function on_attacher(keys, isasync)
  local fmt_cmd =
      "vim.lsp.buf.formatting" .. (isasync and "" or "_sync") .. "()"
  return function(client, _)
    for cmd, key in pairs(keys) do nno(key, cmd) end

    local au = {
      ["OrgImports()"] = client.resolved_capabilities.code_action or nil,
      [fmt_cmd] = client.resolved_capabilities.document_formatting or nil,
    }

    if vim.tbl_isempty(au) then return end

    vim.cmd(("au Setup BufWritePre <buffer> lua %s"):format(
                table.concat(vim.tbl_keys(au), "; ")))
  end
end

local sumneko_root = "/home/alex/.lua_lsp"
local sumneko_binary = sumneko_root .. "/bin/Linux/lua-language-server"
local lsp_cfg = {
  bashls = {},
  cssls = {},
  dockerls = {},
  -- https://github.com/tomaskallup/dotfiles/blob/master/nvim/lua/lsp-config.lua,
  -- https://github.com/lukas-reineke/dotfiles/tree/master/vim/lua
  -- https://github.com/tsuyoshicho/vim-efm-langserver-settings
  efm = {
    on_attach = on_attacher(keys_cfg, async),
    init_options = {documentFormatting = true, codeAction = false},
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
  r_language_server = {on_attach = on_attacher(keys_cfg, async)},
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
      on_attacher(keys_cfg)(client, bufnr)
    end,
    settings = {documentFormatting = false},
  },
  vimls = {},
  vuels = {},
  yamlls = {},
}

local diagnostics_cfg = {
  underline = true,
  virtual_text = {spacing = 5, prefix = "->"},
  signs = false,
  update_in_insert = true,
}

local treesitter_cfg = {
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

return function()
  local lsp = require "lspconfig"
  for k, v in pairs(lsp_cfg) do
    lsp[k].setup(vim.tbl_extend("keep", v, {on_attach = on_attacher(keys_cfg)}))
  end

  vim.lsp.handlers["textDocument/publishDiagnostics"] =
      vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, diagnostics_cfg)

  require"nvim-treesitter.configs".setup(treesitter_cfg)

  vim.cmd("set termguicolors")
  require"colorizer".setup()
end
