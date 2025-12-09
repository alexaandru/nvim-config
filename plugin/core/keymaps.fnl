(local {: toggle : select : close : send : prompt} (require :sidekick.cli))
(local {: select_textobject} (require :nvim-treesitter-textobjects.select))
(local textobj-sel #(select_textobject $ :textobjects))
(local gitsigns (require :gitsigns))

(let [_m #(vim.keymap.set $ $2 $3 $4)
      nmap #(_m :n $ $2 $3)
      vmap #(_m :v $ $2 $3)
      zmap #(_m [:n :t :i :x] $ $2 $3)
      xnmap #(_m [:x :n] $ $2 $3)
      xomap #(_m [:x :o] $ $2 $3)]
  (nmap :gb "<Cmd>ls<CR>:b<Space>" {:silent true :desc "Go to Buffer"})
  (nmap :db "<Cmd>%bd<bar>e#<CR>" {:silent true :desc "Delete All Buffers"})
  (nmap :<F3> :<Cmd>Zoom<CR> {:silent true :desc "Toggle Zen Mode"})
  (nmap :<F6> :<Cmd>RunTests<CR> {:silent true :desc "Run Go Tests"})
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
  (xnmap :<Leader>ap #(prompt) {:desc "Sidekick Select Prompt"})
  ;; Gitsigns
  (nmap "]c" #(if vim.wo.diff
                  (vim.cmd.normal {1 "]c" :bang true})
                  (gitsigns.nav_hunk :next)))
  (nmap "[c" #(if vim.wo.diff
                  (vim.cmd.normal {1 "[c" :bang true})
                  (gitsigns.nav_hunk :prev)))
  (nmap :<leader>hs gitsigns.stage_hunk)
  (nmap :<leader>hr gitsigns.reset_hunk)
  (vmap :<leader>hs #(gitsigns.stage_hunk [(vim.fn.line ".") (vim.fn.line :v)]))
  (vmap :<leader>hr #(gitsigns.reset_hunk [(vim.fn.line ".") (vim.fn.line :v)]))
  (nmap :<leader>hS gitsigns.stage_buffer)
  (nmap :<leader>hR gitsigns.reset_buffer)
  (nmap :<leader>hp gitsigns.preview_hunk)
  (nmap :<leader>hi gitsigns.preview_hunk_inline)
  (nmap :<leader>hb #(gitsigns.blame_line {:full true}))
  (nmap :<leader>hd gitsigns.diffthis)
  (nmap :<leader>hD #(gitsigns.diffthis "~"))
  (nmap :<leader>hQ #(gitsigns.setqflist :all))
  (nmap :<leader>hq gitsigns.setqflist)
  (nmap :<leader>tb gitsigns.toggle_current_line_blame)
  (nmap :<leader>tw gitsigns.toggle_word_diff)
  (xomap :ih gitsigns.select_hunk)
  ;; Tree-sitter Textobjects
  (let [obj-sel {:af "@function.outer"
                 :if "@function.inner"
                 :ab "@block.outer"
                 :ib "@block.inner"
                 :ac "@class.outer"
                 :ic "@class.inner"}]
    (each [k v (pairs obj-sel)]
      (xomap k #(textobj-sel v)))))
