(local fzf (require :fzf-lua))

(fn FzFiles [opts]
  (set-forcibly! opts (or opts {}))
  (let [cmd (icollect [_ p (ipairs (vim.opt.wildignore:get))]
              (string.format "--glob '!%s'" (p:gsub "^*/" "/")))
        cmd (vim.fn.join cmd)
        cmd (string.format "rg --files -i %s" cmd)
        cwd (or (?. opts :args) nil)
        cwd (if (= cwd "") nil cwd)]
    (fzf.files {: cmd : cwd})))

(fn LspCapabilities []
  (vim.notify (vim.inspect (collect [_ c (pairs (vim.lsp.get_clients {:buffer 0}))]
                             c.name
                             (collect [k v (pairs c.server_capabilities)]
                               (if v (values k v)))))))

(fn SetProjMaster []
  (let [cmd "git branch -a|grep \\*|cut -f2 -d \" \""
        b (vim.fn.system cmd)
        master (string.gsub b "\n" "")]
    (set vim.w.proj_master master)))

(fn LastWindow []
  (fn is-quittable []
    (let [{:buftype bt :filetype ft} (vim.fn.getbufvar "%" "&")]
      (or (vim.tbl_contains [:quickfix :terminal :nofile] bt) (= ft :netrw))))

  (fn last-window []
    (= -1 (vim.fn.winbufnr 2)))

  (if (and (is-quittable) (last-window))
      (vim.cmd "norm ZQ")))

(fn LspHintsToggle []
  (when vim.b.hints_on
    (if (not vim.b.hints) (set vim.b.hints (vim.lsp.inlay_hint.is_enabled)))
    (set vim.b.hints (not vim.b.hints))
    (vim.lsp.inlay_hint.enable vim.b.hints {:bufnr 0})))

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

{:Grep {:cmd "sil grep <args>" :bar false}
 :PackUpdate "lua vim.pack.update()"
 :FzFiles {:cmd FzFiles :complete :file}
 :Term {:cmd "12split | term <args>" :nargs "*"}
 :SetProjRoot "let w:proj_root = fnamemodify(finddir('.git/..', expand('%:p:h').';'), ':p')"
 : SetProjMaster
 :CdProjRoot "SetProjRoot | cd `=w:proj_root`"
 :JumpToLastLocation "let b:pos = line('''\"') | if b:pos && b:pos <= line('$') | exe b:pos | endif"
 :SaveAndClose "up | bdel"
 : LastWindow
 :Scratchify "setl nobl bt=nofile bh=delete noswf"
 :Scratch "<mods> new +Scratchify"
 :AutoWinHeight "sil exe max([min([line('$')+1, 16]), 1]).'wincmd _'"
 : LspCapabilities
 : LspHintsToggle
 :JQ {:cmd "<line1>,<line2>!jq -S ." :range true}}
