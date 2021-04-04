-- luacheck: globals vim
local cfg = require "config"
local lsp = require "lsp"
local util = require "util"
local packadd, let, au, com, set, sig, colo, map =
    util.unpack {"packadd", "let", "au", "com", "set", "sig", "colo", "map"}

util.unpack_G {
  "GitStatus",
  "CfgComplete",
  "ProjRelativePath",
  "Format",
  "OrgImports",
  "OrgJSImports",
  "LspCapabilities",
  "RunTests",
}

util.disable_providers {"python", "python3", "node", "ruby", "perl"}

-- TODO: https://github.com/neovim/neovim/issues/12587 when resolved,
-- remove https://github.com/antoinemadec/FixCursorHold.nvim
-- (loaded from start not opt, hence not listed below)
packadd {
  "nvim-lspconfig",
  "nvim-lspupdate",
  "nvim-treesitter",
  "nvim-treesitter-textobjects",
  "nvim-colorizer",
  "lsp_signature",
}

let(cfg.vars)

lsp.setup()

local ts = require "nvim-treesitter.configs"
ts.setup(cfg.treesitter)

set(cfg.options)

au(cfg.autocmd)

require"colorizer".setup()

com(cfg.commands)

map(cfg.keys.global)

sig(cfg.signs)

util.setup_notify()

colo "froggy"
