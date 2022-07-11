(local term-name :Terminal)

(fn hide-pane [pane]
  (vim.cmd (.. "exe '" pane "hide'")))

(fn show-buf [term-name]
  (vim.cmd (.. "exe 'bo 12split' | exe 'b " term-name "' | startinsert")))

(fn create-term [term-name]
  (vim.cmd "exe 'bo 12split'")
  (vim.cmd "lcd %:p:h")
  (vim.cmd :term)
  (vim.cmd "set nobl noswf bh=delete | startinsert")
  (vim.cmd (.. "exe 'f " term-name "'")))

(fn ToggleTerm []
  (let [pane (vim.fn.bufwinnr term-name)
        buf (vim.fn.bufexists term-name)]
    (if (> pane 0) (hide-pane pane)
        (> buf 0) (show-buf term-name)
        (create-term term-name))))

(vim.api.nvim_create_user_command :ToggleTerm ToggleTerm {:nargs "*" :bar true})

(vim.keymap.set :n :<C-Enter> ToggleTerm {:silent true})
(vim.keymap.set :t :<C-Enter> ToggleTerm {:silent true})

