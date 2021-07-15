local cfg = {}

for _, v in ipairs {
  "autocmd",
  "commands",
  "keys",
  "options",
  "plugins",
  "signs",
  "treesitter",
  "vars",
} do cfg[v] = require("config." .. v) end

return cfg
