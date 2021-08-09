;; https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json
(let [expand vim.fn.expand
      root (expand :$HOME/.lua_lsp)
      binary (.. root :/bin/Linux/lua-language-server)]
  {:cmd [binary :-E (.. root :/main.lua)]
   :settings {:Lua {:runtime {:version :LuaJIT
                              :path (vim.split package.path ";")}
                    :diagnostics {:globals [:vim]}
                    :workspace {:library {(expand :$VIMRUNTIME/lua) true
                                          (expand :$VIMRUNTIME/lua/vim/lsp) true}
                                :ignoreDir nil}}}})

