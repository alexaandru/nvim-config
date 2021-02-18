local root = "/home/alex/.lua_lsp"
local binary = root .. "/bin/Linux/lua-language-server"

-- https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json
return {
  cmd = {binary, "-E", root .. "/main.lua"},
  settings = {
    Lua = {
      runtime = {version = "LuaJIT", path = vim.split(package.path, ";")},
      diagnostics = {globals = {"vim"}},
      workspace = {
        library = {
          [vim.fn.expand("$VIMRUNTIME/lua")] = true,
          [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
        },
      },
    },
  },
}
