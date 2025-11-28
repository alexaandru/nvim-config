(local {: toggle : select : close : send : prompt} (require :sidekick.cli))

(let [nmap #(vim.keymap.set :n $1 $2 $3)
      zmap #(vim.keymap.set [:n :t :i :x] $1 $2 $3)
      xnmap #(vim.keymap.set [:n :x] $1 $2 $3)]
  (nmap :gb "<Cmd>ls<CR>:b<Space>" {:silent true :desc "Go to Buffer"})
  (nmap :db "<Cmd>%bd<bar>e#<CR>" {:silent true :desc "Delete All Buffers"})
  (nmap :<F3> vim.cmd.only {:silent true :desc "Zen mode"})
  (nmap :<F7> :<Cmd>Inspect<CR> {:desc "Inspect TS node under cursor"})
  (nmap :<F8> :<Cmd>Gdiff<CR> {:desc "Git Diff"})
  (nmap :<Leader>w :<Cmd>SaveAndClose<CR>
        {:silent true :desc "Save and Close Buffer"})
  (nmap :<Space> "@=((foldclosed(line('.')) < 0) ? 'zc' : 'zO')<CR>"
        {:silent true :desc "Toggle Fold"})
  (nmap :Q :<Nop> {:silent true})
  (nmap :<Esc> :<Cmd>noh<CR>)
  (nmap "," ":find ")
  ;; Sidekick
  (zmap :<C-.> #(toggle {:name :claude :focus true}) {:desc "Sidekick Toggle"})
  (zmap :<C-/> #(select {:filter {:installed true}})
        {:desc "Sidekick Toggle Claude"})
  (zmap :<Leader>ac #(close) {:desc "Detach a CLI Session"})
  (xnmap :<Leader>at #(send {:msg "{this}"}) {:desc "Sidekick Send This"})
  (nmap :<Leader>af #(send {:msg "{file}"}) {:desc "Sidekick Send File"})
  (xnmap :<Leader>av #(send {:msg "{selection}"})
         {:desc "Sidekick Send Selection"})
  (xnmap :<Leader>ap #(prompt) {:desc "Sidekick Select Prompt"}))
