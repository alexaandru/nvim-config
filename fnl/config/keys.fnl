; NOTE: at ~20ms, this is one of the slowest parts of config. Why?
(let [S {:silent true}
      toggle-fold "@=((foldclosed(line('.')) < 0) ? 'zC' : 'zO')<CR>"
      syn-stack "<Cmd>echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, \"name\")')<CR>"
      dap (require :dap)
      dapui (require :dapui)
      widgets (require :dap.ui.widgets)
      sidebar (widgets.sidebar widgets.scopes)]
  {:n [[:gb "<Cmd>ls<CR>:b<Space>" S]
       [:db "<Cmd>%bd<bar>e#<CR>" S]
       [:<F3> #(vim.cmd :only) S]
       [:<Leader>z dap.continue S]
       [:<Leader>b dap.toggle_breakpoint S]
       [:<Leader>o dap.step_over S]
       [:<Leader>i dap.step_into S]
       [:<Leader>x dap.step_out S]
       [:<Leader>r dap.repl.toggle S]
       [:<Leader>u dapui.toggle S]
       [:<Leader>t sidebar.toggle S]
       [:<F8> :<Cmd>Gdiff<CR> S]
       [:<Leader>w :<Cmd>SaveAndClose<CR> S]
       [:<Space> toggle-fold S]
       [:Q :<Nop> S]
       [:<Esc> :<Cmd>noh<CR>]
       ["," ":find "]
       [:<F10> syn-stack S]]
   :i [["'" "''<Left>"] ["(" "()<Left>"] ["[" "[]<Left>"] ["{" "{}<Left>"]]})

