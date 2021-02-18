-- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
return {
  settings = {
    gopls = {
      analyses = {fieldalignment = true, shadow = true, unusedparams = true},
      codelenses = {gc_details = true, test = true, generate = true, tidy = true},
      staticcheck = true,
      gofumpt = true,
      hoverKind = "SynopsisDocumentation",
    },
  },
}
