(local gitsigns (require :gitsigns))

(fn [bufnr]
  (fn map [mode l r opts]
    (set-forcibly! opts (or opts {}))
    (set opts.buffer bufnr)
    (vim.keymap.set mode l r opts))

  (map :n "]c" #(if vim.wo.diff
                    (vim.cmd.normal {1 "]c" :bang true})
                    (gitsigns.nav_hunk :next)))
  (map :n "[c" #(if vim.wo.diff
                    (vim.cmd.normal {1 "[c" :bang true})
                    (gitsigns.nav_hunk :prev)))
  (map :n :<leader>hs gitsigns.stage_hunk)
  (map :n :<leader>hr gitsigns.reset_hunk)
  (map :v :<leader>hs
       #(gitsigns.stage_hunk [(vim.fn.line ".") (vim.fn.line :v)]))
  (map :v :<leader>hr
       #(gitsigns.reset_hunk [(vim.fn.line ".") (vim.fn.line :v)]))
  (map :n :<leader>hS gitsigns.stage_buffer)
  (map :n :<leader>hR gitsigns.reset_buffer)
  (map :n :<leader>hp gitsigns.preview_hunk)
  (map :n :<leader>hi gitsigns.preview_hunk_inline)
  (map :n :<leader>hb #(gitsigns.blame_line {:full true}))
  (map :n :<leader>hd gitsigns.diffthis)
  (map :n :<leader>hD #(gitsigns.diffthis "~"))
  (map :n :<leader>hQ #(gitsigns.setqflist :all))
  (map :n :<leader>hq gitsigns.setqflist)
  (map :n :<leader>tb gitsigns.toggle_current_line_blame)
  (map :n :<leader>tw gitsigns.toggle_word_diff)
  (map [:o :x] :ih gitsigns.select_hunk))
