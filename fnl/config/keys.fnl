(let [S {:silent true}
      toggle-fold "@=((foldclosed(line('.')) < 0) ? 'zc' : 'zO')<CR>"
      syn-stack "<Cmd>echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, \"name\")')<CR>"]
  {:n [[:gb "<Cmd>ls<CR>:b<Space>" S]
       [:db "<Cmd>%bd<bar>e#<CR>" S]
       [:<C-P> :<Cmd>FzFiles<CR> S]
       [:<C-S-P> :<Cmd>FzfLua<CR> S]
       [:<C-Q> "<Cmd>FzfLua live_grep<CR>" S]
       [:<F5> :<Cmd>Inspect<CR>]
       [:<F3> vim.cmd.only S]
       [:<F8> :<Cmd>Gdiff<CR> S]
       [:<Leader>w :<Cmd>SaveAndClose<CR> S]
       [:<Leader>s #(pcall vim.treesitter.start 0)]
       [:<Space> toggle-fold S]
       [:Q :<Nop> S]
       [:<Esc> :<Cmd>noh<CR>]
       ["," ":find "]
       [:<F10> syn-stack S]]
   :i [["'" "''<Left>"] ["(" "()<Left>"] ["[" "[]<Left>"] ["{" "{}<Left>"]]})
