(local fennel (require :fennel))

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

;; https://github.com/neovim/neovim/pull/13896
(fn get-range []
  ;; https://github.com/neovim/neovim/pull/13896#issuecomment-774680224
  (var [_ l1] (vim.fn.getpos :v))
  (var [_ l2] (vim.fn.getcurpos))
  (when (= l1 l2)
    (set l1 1)
    (set l2 (vim.fn.line "$")))
  (when (> l1 l2)
    (local tmp l1)
    (set l1 l2)
    (set l2 tmp))
  (let [lines (vim.fn.getline l1 l2)
        text (table.concat lines "\n")]
    text))

(fn FnlEval []
  (if (= vim.bo.filetype :fennel)
      (let [text (get-range)
            out (fennel.eval text)]
        (fnl-do (vim.inspect out) true))))

(fn FnlCompile []
  (if (= vim.bo.filetype :fennel)
      (let [text (get-range)
            out (fennel.compileString text)]
        (fnl-do out))))

{: FnlEval : FnlCompile}

