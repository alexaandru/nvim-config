(fn fnl-do [ok code noformat]
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
      (if (and ok (not noformat)) (cmd "%!lua-format"))
      (cmd "setl nofoldenable")
      (vim.fn.setpos "." [0 0 0 0]))))

;; https://github.com/neovim/neovim/pull/13896
(fn get-range []
  (let [;; https://github.com/neovim/neovim/pull/13896#issuecomment-774680224
        [_ v1] (vim.fn.getpos :v)
        [_ v2] (vim.fn.getcurpos)]
    (if (not= v2 v1)
        (values (math.min v1 v2) (math.max v1 v2))
        (values 1 (vim.fn.line "$")))))

(fn FnlEval []
  (if (= vim.bo.filetype :fennel)
      (let [(start stop) (get-range)
            {: eval-range} (require :hotpot.api.eval)
            (any) (eval-range 0 start stop)]
        (fnl-do true (vim.inspect any) true))))

(fn FnlCompile []
  (if (= vim.bo.filetype :fennel)
      (let [(start stop) (get-range)
            {: compile-range} (require :hotpot.api.compile)
            (ok code) (compile-range 0 start stop)]
        (fnl-do ok code))))

{: FnlEval : FnlCompile}

