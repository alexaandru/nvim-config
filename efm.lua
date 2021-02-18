local function fmtCmd(cmd)
  return {formatCommand = cmd, formatStdin = true}
end

local function lintCmd(cmd, fmt)
  fmt = fmt or "%f:%l:%c: %m"
  return {lintCommand = cmd, lintStdin = true, lintFormats = {fmt}, lintIgnoreExitCode = true}
end

local prettier = fmtCmd("npx prettier --arrow-parens avoid --stdin-filepath ${INPUT}")

local eslint = { -- WIP
  lintCommand = "npx eslint -f unix ${INPUT}",
  lintStdin = false,
  lintFormats = {
    -- src/main.js:16:5: 'zoo' is assigned a value but never used. [Error/no-unused-vars]
    "%f:%l:%c: %m [%trror",
    "%f:%l:%c: %m [%tarn",
    "%f:%l:%c: %m [%tnfo",
    "%f:%l:%c: %m",
  },
}

local _ = eslint

-- https://github.com/tomaskallup/dotfiles/blob/master/nvim/lua/lsp-config.lua,
-- https://github.com/lukas-reineke/dotfiles/tree/master/vim/lua
-- https://github.com/tsuyoshicho/vim-efm-langserver-settings
local cfg = {
  lua = {
    fmtCmd("lua-format -i"),
    lintCmd([[bash -c 'luacheck --formatter plain --globals vim -- ${INPUT}|sed s"/^/Warn /"']],
            "%tarn %f:%l:%c: %m"),
  },
  tf = {lintCmd("tflint ${INPUT}")},
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
      -- lintCommand = [[bash -c 'golangci-lint run|grep ^$(realpath --relative-to . ${INPUT})|sed s"/^/Info /"']],
      lintCommand = [[bash -c 'golangci-lint run --out-format json|filter_lint.sh|grep $(realpath --relative-to . ${INPUT})']],
      lintStdin = false,
      lintFormats = {
        "%trror %f:%l:%c: %m",
        "%tarn %f:%l:%c: %m",
        "%tnfo %f:%l:%c: %m",
        "%tint %f:%l:%c: %m",
      },
      lintIgnoreExitCode = true,
    },
  },
}

return {
  on_attach = require"util".on_attacher(true),
  init_options = {documentFormatting = true, codeAction = false},
  filetypes = vim.tbl_keys(cfg),
  settings = {rootMarkers = {".git"}, languages = cfg},
}
