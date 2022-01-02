(fn LspCapabilities []
  (print (vim.inspect (collect [_ c (pairs (vim.lsp.buf_get_clients))]
                        (values c.name
                                (collect [k v (pairs c.resolved_capabilities)]
                                  (if v (values k v))))))))

(fn with-config [s]
  (string.format s (vim.fn.stdpath :config)))

(local cfg-files ;;
       (let [c (vim.fn.stdpath :config)
             glob #(vim.fn.glob (.. c "/" $) 0 1)
             files (glob :fnl/**/*.fnl)
             rm-prefix #($:sub (+ 6 (length c)))]
         (vim.tbl_map rm-prefix files)))

(fn complete [arg-lead]
  (vim.tbl_filter #(or (= arg-lead "") ($:find arg-lead)) cfg-files))

(fn kee [cmd]
  #(let [last-search (vim.fn.getreg "@/")
         start (or $.line1 :1)
         stop (or $.line2 "$")
         save (vim.fn.winsaveview)
         fmt string.format
         cmd (fmt "kee keepj keepp %s,%ss%se" start stop cmd)]
     (vim.cmd cmd)
     (vim.fn.winrestview save)
     (vim.fn.setreg "@/" last-search)))

(local {: FnlEval : FnlCompile} (require :eval))

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
;;   :nargs - if args> is present in command string, then is set to 1.

{:Cfg {:cmd (with-config "e %s/fnl/<args>") : complete}
 :Grep "silent grep <args>"
 :Term {:cmd "12split | term <args>" :nargs "*"}
 :LoadLocalCfg "if filereadable('.nvimrc') | so .nvimrc | endif"
 :SetProjRoot "let w:proj_root = fnamemodify(finddir('.git/..', expand('%:p:h').';'), ':p')"
 :CdProjRoot "SetProjRoot | cd `=w:proj_root`"
 :Gdiff "SetProjRoot | exe 'silent !cd '.w:proj_root.' && git show HEAD^:'.luaeval('ProjRelativePath()').' > /tmp/gdiff' | diffs /tmp/gdiff"
 :JumpToLastLocation "let b:pos = line('''\"') | if b:pos && b:pos <= line('$') | exe b:pos | endif"
 :TrimTrailingSpace (kee "/\\s\\+$//")
 :TrimTrailingBlankLines (kee "/\\($\\n\\s*\\)\\+\\%$//")
 :SquashBlankLines (kee "/\\(\\n\\)\\{3,}/\\1\\1/")
 :TrimBlankLines (kee "/\\(\\n\\)\\{2,}/\\1/")
 :SaveAndClose "up | bdel"
 :LastWindow "if (&buftype ==# 'quickfix' || &buftype ==# 'terminal' || &buftype ==# 'nofile' || &filetype ==# 'netrw') && winbufnr(2) ==# -1 | q | endif"
 :Scratchify "setl nobl bt=nofile bh=delete noswf"
 :Scratch "<mods> new +Scratchify"
 :AutoWinHeight "silent exe max([min([line('$'), 12]), 1]).'wincmd _'"
 :AutoIndent "silent norm gg=G`."
 : LspCapabilities
 :PlugUpdate "silent exe '! cd' stdpath('config').' && git submodule foreach git pull'"
 : FnlCompile
 : FnlEval
 :JQ {:cmd "<line1>,<line2>!jq ." :range true}}

