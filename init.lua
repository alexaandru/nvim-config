local cfg = require "config"
local util = require "util"
local pa, au, com, set, hi, sig, colo, kmap, vimL =
    util.unpack {"pa", "au", "com", "set", "hi", "sig", "colo", "kmap", "exec"}

local providers = {"python", "python3", "node", "ruby", "perl"}
vim.tbl_map(util.disable_provider, providers)

pa {
  "nvim-lspconfig",
  "nvim-lspupdate",
  "nvim-treesitter",
  "nvim-treesitter-textobjects",
  "nvim-colorizer.lua",
  "deus",
  "gomod",
  "site-util",
}

set(cfg.options)

au(cfg.autocmd)

util.lsp_setup(cfg)

local ts = require "nvim-treesitter.configs"
ts.setup(cfg.treesitter)

require"colorizer".setup()

vim.env.GOFLAGS = "-tags=development"
vim.g.config_files = util.configs()

vimL [[func! CfgList(A, L, P)
  return filter(copy(g:config_files), {_,v -> v =~ '^'.a:A})
endf]]

com(cfg.commands)

kmap(cfg.keys.global)

colo "embark"

hi(cfg.highlight)

sig(cfg.signs)
