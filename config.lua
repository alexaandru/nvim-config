local cfg = {}

for _, v in ipairs {
  "vars",
  "options",
  "autocmd",
  "commands",
  "highlight",
  "signs",
  "keys",
  "diagnostics",
  "treesitter",
} do cfg[v] = require("config." .. v) end

return cfg
