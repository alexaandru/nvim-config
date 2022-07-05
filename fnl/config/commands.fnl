(fn LspCapabilities []
  (vim.notify (vim.inspect (collect [_ c (pairs (vim.lsp.buf_get_clients))]
                             c.name
                             (collect [k v (pairs c.server_capabilities)]
                               (if v (values k v)))))))

(fn PlugUpdate []
  (local autd "Already up to date.")

  (fn on_stdout [_ data]
    (if (not= (?. data 1) autd)
        (print (table.concat data "\n"))))

  (fn on_exit [_ code]
    (if (> code 0) (print :Error code) (print "Plugins update completed!")))

  (let [cfg (vim.fn.stdpath :config)
        cmd "cd '%s' && git submodule --quiet foreach git pull"
        cmd (cmd:format cfg)
        opts {: on_exit : on_stdout :on_stderr on_stdout}]
    (vim.fn.jobstart cmd opts)))

(fn Gdiff []
  (vim.cmd :SetProjRoot)
  (let [path (vim.fn.expand "%:p")
        proj-rel-path (path:sub (+ (length vim.w.proj_root) 1))
        cmd "exe 'sil !lcd %s && git show HEAD^:%s > /tmp/gdiff' | diffs /tmp/gdiff"
        cmd (cmd:format vim.w.proj_root proj-rel-path)]
    (vim.cmd cmd)))

(fn LastWindow []
  (fn is-quittable []
    (let [{:buftype bt :filetype ft} (vim.fn.getbufvar "%" "&")]
      (or (vim.tbl_contains [:quickfix :terminal :nofile] bt) (= ft :netrw))))

  (fn last-window []
    (= -1 (vim.fn.winbufnr 2)))

  (if (and (is-quittable) (last-window))
      (vim.cmd "norm ZQ")))

;; Format is: {CommandName CommandSpec, ...}
;; where CommandSpec is either String, Table or Lua function.
;;
;; If it is Table, then the command itself must be passed in .cmd, the
;; rest of CommandSpec is treated as arguments to command:
;;   :cmd - command (as string) or function;
;;   :bar - autofilled for strings based on absence of pipe symbol and
;;          always ON for functions, unless already set;
;;   :range - if <line1> is present in command string (or command
;;            is a function), then range is set automaticall to %;
;;   :nargs - if <args> is present in command string, then is set to 1,
;;            for functions it is always set to "*".
{:Grep "sil grep <args>"
 :Term {:cmd "12split | term <args>" :nargs "*"}
 :SetProjRoot "let w:proj_root = fnamemodify(finddir('.git/..', expand('%:p:h').';'), ':p')"
 :CdProjRoot "SetProjRoot | cd `=w:proj_root`"
 : Gdiff
 :JumpToLastLocation "let b:pos = line('''\"') | if b:pos && b:pos <= line('$') | exe b:pos | endif"
 :SaveAndClose "up | bdel"
 : LastWindow
 :Scratchify "setl nobl bt=nofile bh=delete noswf"
 :Scratch "<mods> new +Scratchify"
 :AutoWinHeight "sil exe max([min([line('$'), 12]), 1]).'wincmd _'"
 : LspCapabilities
 : PlugUpdate
 :JQ {:cmd "<line1>,<line2>!jq ." :range true}}

