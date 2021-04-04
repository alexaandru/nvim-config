local cfg = {}

for _, v in ipairs {
  "vars",
  "options",
  "autocmd",
  "commands",
  "signs",
  "keys",
  "treesitter",
} do cfg[v] = require("config." .. v) end

return cfg
