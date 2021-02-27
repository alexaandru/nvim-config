local cfg = require "config"
local lsp = require "lsp"
local util = require "util"
local packadd, let, au, com, se, sig, colo, map, unpack_G =
    util.unpack {"pa", "let", "au", "com", "se", "sig", "colo", "map", "unpack_G"}

unpack_G {"GitStatus", "CfgComplete", "ProjRelativePath", "BufWritePre", "LspCapabilities"}

util.disable_providers {"python", "python3", "node", "ruby", "perl"}

util.notify_beautify()

-- TODO: https://github.com/neovim/neovim/issues/12587 when resolved,
-- remove https://github.com/antoinemadec/FixCursorHold.nvim
packadd {
  "nvim-lspconfig",
  "nvim-lspupdate",
  "nvim-treesitter",
  "nvim-treesitter-textobjects",
  "nvim-colorizer",
  "gomod",
  "deus",
}

let(cfg.vars)

lsp.setup(cfg.diagnostics)

local ts = require "nvim-treesitter.configs"
ts.setup(cfg.treesitter)

se(cfg.options)

au(cfg.autocmd)

require"colorizer".setup()

com(cfg.commands)

map(cfg.keys.global)

sig(cfg.signs)

colo "deus" -- embark, slate
colo "deus" -- some highlights only apply on a 2nd run, no idea why...
