(let [nmap #(vim.keymap.set :n $1 $2 $3)
      imap #(vim.keymap.set :i $1 $2 $3)]
  (nmap :gb "<Cmd>ls<CR>:b<Space>" {:silent true :desc "Go to Buffer"})
  (nmap :db "<Cmd>%bd<bar>e#<CR>" {:silent true :desc "Delete All Buffers"})
  (nmap :<F3> vim.cmd.only {:silent true :desc "Zen mode"})
  (nmap :<F5> :<Cmd>Inspect<CR> {:desc "Inspect TS node under cursor"})
  (nmap :<F8> :<Cmd>Gdiff<CR> {:desc "Git Diff"})
  (nmap :<Leader>w :<Cmd>SaveAndClose<CR>
        {:silent true :desc "Save and Close Buffer"})
  (nmap :<Space> "@=((foldclosed(line('.')) < 0) ? 'zc' : 'zO')<CR>"
        {:silent true :desc "Toggle Fold"})
  (nmap :Q :<Nop> {:silent true})
  (nmap :<Esc> :<Cmd>noh<CR>)
  (nmap "," ":find ")
  (imap "'" "''<Left>")
  (imap "(" "()<Left>")
  (imap "[" "[]<Left>")
  (imap "{" "{}<Left>"))
