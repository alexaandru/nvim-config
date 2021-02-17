local keys_cfg = { -- LuaFormatter off
  buf = {
    declaration      = "gd",
    definition       = "<c-]>",
    hover            = "<F1>",
    implementation   = "gD",
    signature_help   = "<c-k>",
    type_definition  = "1gD",
    references       = "gr",
    document_symbol  = "g0",
    workspace_symbol = "gW",
    rename           = "<F2>",
    code_action      = "<F16>"},
  diagnostic = {
    goto_next        = "<M-Right>",
    goto_prev        = "<M-Left>",
    set_loclist      = "<F7>"},
} -- LuaFormatter on

local function fmtCmd(cmd)
  return {formatCommand = cmd, formatStdin = true}
end

local function lintCmd(cmd, fmt)
  fmt = fmt or "%f:%l:%c: %m"
  return {lintCommand = cmd, lintStdin = true, lintFormats = {fmt}, lintIgnoreExitCode = true}
end

local prettier = fmtCmd("npx prettier --arrow-parens avoid --stdin-filepath ${INPUT}")

-- https://github.com/tomaskallup/dotfiles/blob/master/nvim/lua/lsp-config.lua,
-- https://github.com/lukas-reineke/dotfiles/tree/master/vim/lua
-- https://github.com/tsuyoshicho/vim-efm-langserver-settings
local efm_cfg = {
  lua = {fmtCmd("lua-format -i"), lintCmd("luacheck --formatter plain --globals vim -- ${INPUT}")},
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
  go = {
    {
      lintCommand = [[bash -c 'golangci-lint run|grep ^$(realpath --relative-to . ${INPUT})|sed s"/^/Info /"']],
      lintStdin = false,
      lintFormats = {"%tnfo %f:%l:%c: %m"},
      lintIgnoreExitCode = true,
    },
  },
}

local function nno(key, cmd)
  cmd = ("<Cmd>lua vim.lsp.%s()<CR>"):format(cmd)
  vim.api.nvim_buf_set_keymap(0, "n", key, cmd, {noremap = true, silent = true})
end

local function on_attacher(keys, isasync)
  local fmt_cmd = "vim.lsp.buf.formatting" .. (isasync and "" or "_sync") .. "()"
  return function(client, bufnr)
    for c1, kx in pairs(keys) do --
      for c2, k in pairs(kx) do nno(k, c1 .. "." .. c2) end
    end

    local okFmt = client.name ~= "efm" or vim.fn.getbufvar(bufnr, "&filetype") ~= "go"
    local orgImp = client.resolved_capabilities.code_action
                       and (type(client.resolved_capabilities.code_action) == "boolean"
                           or client.resolved_capabilities.code_action.codeActionKinds
                           and vim.tbl_contains(client.resolved_capabilities.code_action
                                                    .codeActionKinds, "source.organizeImports"))
    local au = {
      ["require'util'.OrgImports()"] = orgImp or nil,
      [fmt_cmd] = okFmt and client.resolved_capabilities.document_formatting or nil,
    }

    if vim.tbl_isempty(au) then return end

    vim.cmd(("au Setup BufWritePre <buffer> lua %s"):format(table.concat(vim.tbl_keys(au), "; ")))
  end
end

local sumneko_root = "/home/alex/.lua_lsp"
local sumneko_binary = sumneko_root .. "/bin/Linux/lua-language-server"
local async = true
local lsp_cfg = {
  bashls = {},
  cssls = {},
  dockerls = {},
  efm = {
    on_attach = on_attacher(keys_cfg, async),
    init_options = {documentFormatting = true, codeAction = false},
    filetypes = vim.tbl_keys(efm_cfg),
    settings = {rootMarkers = {".git"}, languages = efm_cfg},
  },
  gopls = { -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
    settings = {
      gopls = {
        analyses = {fieldalignment = true, shadow = true, unusedparams = true},
        codelenses = {gc_details = true, test = true, generate = true, tidy = true},
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
  signs = true,
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
      keymaps = {
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

local packadd = require"util".packadd
local set = require"util".set

return function()
  packadd "nvim-lspconfig"
  packadd "nvim-lspupdate"
  packadd "nvim-treesitter"
  packadd "nvim-treesitter-textobjects"
  packadd "nvim-colorizer.lua"
  packadd "nvim-deus"
  packadd "gomod"
  packadd "site-util"

  local lsp = require "lspconfig"
  for k, v in pairs(lsp_cfg) do
    lsp[k].setup(vim.tbl_extend("keep", v, {on_attach = on_attacher(keys_cfg)}))
  end

  vim.lsp.handlers["textDocument/publishDiagnostics"] =
      vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, diagnostics_cfg)

  require"nvim-treesitter.configs".setup(treesitter_cfg)

  set "termguicolors"
  require"colorizer".setup()
end
