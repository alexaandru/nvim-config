; TODO: use more API commands and rely less on vimL
; TODO: reuse diff buffer (similar to how FnlEval does it).

; Gdiff shows diff of current file against its version from another branch.
; By default it diffs against master, a name of a different branch may be 
; passed as an argument.
(fn Gdiff [opts]
  (vim.cmd :SetProjRoot)
  (vim.cmd :SetProjMaster) ; TODO: fix it, currently it shows current branch instead of master/main.
  (let [branch (if (= opts.args "") :master opts.args)
        path (vim.fn.expand "%:p")
        proj-rel-path (path:sub (+ (length vim.w.proj_root) 1))
        cmd "setl scrollbind diff | vnew | setl scrollbind diff | Scratchify | r !git show %s:%s"
        cmd (cmd:format branch proj-rel-path)]
    (vim.cmd cmd)))

(let [opts {:range "%" :nargs "*" :bar true}
      com vim.api.nvim_create_user_command]
  (com :Gdiff Gdiff opts))

