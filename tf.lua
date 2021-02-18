return {
  on_attach = require"util".on_attacher(true),
  filetypes = {"tf"},
  init_options = {experimentalFeatures = {validateOnSave = true}},
}
