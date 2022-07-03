(local fennel (require :fennel))
(local {: get-selection} (require :misc))

(fn fnl-do [code noformat]
  (set vim.wo.scrollbind true)
  (var buf vim.g.luascratch)
  (when (not buf)
    (set buf (vim.api.nvim_create_buf false true))
    (set vim.g.luascratch buf)
    (vim.api.nvim_buf_set_option buf :filetype :lua))
  (let [nextLine (vim.gsplit code "\n" true)
        lines (icollect [v nextLine]
                v)]
    (vim.api.nvim_buf_set_lines buf 0 -1 false lines)
    (let [cmd vim.cmd
          wnum (vim.fn.bufwinnr buf)
          jump-or-split (if (= -1 wnum) (.. :vs|b buf) (.. wnum "wincmd w"))]
      (cmd jump-or-split)
      (if (not noformat) (cmd "%!lua-format"))
      (cmd "setl nofoldenable")
      (vim.fn.setpos "." [0 0 0 0]))))

{:FnlEval #(if (= vim.bo.filetype :fennel)
               (fnl-do (vim.inspect (fennel.eval (get-selection))) true))
 :FnlCompile #(if (= vim.bo.filetype :fennel)
                  (fnl-do (fennel.compileString (get-selection))))}

