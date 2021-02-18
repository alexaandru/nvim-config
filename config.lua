local cfg = {}

for _, v in ipairs {
  "options",
  "autocmd",
  "commands",
  "highlight",
  "signs",
  "keys",
  "lsp",
  "diagnostics",
  "treesitter",
} do cfg[v] = require("config." .. v) end

return cfg
