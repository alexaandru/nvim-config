(local fennel (require :fennel))
(local {: get-selection} (require :util))

(fn show [func noformat]
  (if (= vim.bo.filetype :fennel)
      (let [code (get-selection)
            code (func code)
            code (if noformat (vim.inspect code) code)]
        (set vim.wo.scrollbind true)
        (when (not vim.g.fnl)
          (set vim.g.fnl (vim.api.nvim_create_buf false true))
          (vim.api.nvim_buf_set_option vim.g.fnl :filetype :lua))
        (let [nextLine (vim.gsplit code "\n" true)
              lines (icollect [v nextLine] v)]
          (vim.api.nvim_buf_set_lines vim.g.fnl 0 -1 false lines)
          (let [cmd vim.cmd
                wnum (vim.fn.bufwinnr vim.g.fnl)
                jump-or-split (if (= -1 wnum) (.. :vs|b vim.g.fnl)
                                  (.. wnum "wincmd w"))]
            (cmd jump-or-split)
            (if (not noformat) (cmd "%!lua-format"))
            (cmd "setl nofoldenable")
            (vim.fn.setpos "." [0 0 0 0]))))))

(each [_ mode (ipairs [:n :v])]
  (each [lhs rhs (pairs {:<Leader>c #(show fennel.compileString)
                         :<Leader>e #(show fennel.eval true)})]
    (vim.keymap.set mode lhs rhs {:silent true})))

