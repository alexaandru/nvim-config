(local {: LspCapabilities : LastWindow : Gdiff} (require :misc))
(local {: GolangCI : RunTests} (require :go))
(local {: TrimTrailingSpace
        : TrimTrailingBlankLines
        : SquashBlankLines
        : TrimBlankLines} (require :trim))

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
;;   :nargs - if args> is present in command string, then is set to 1,
;;            for functions it is always set to "*".

{:Grep "silent grep <args>"
 :Term {:cmd "12split | term <args>" :nargs "*"}
 :SetProjRoot "let w:proj_root = fnamemodify(finddir('.git/..', expand('%:p:h').';'), ':p')"
 :CdProjRoot "SetProjRoot | cd `=w:proj_root`"
 : Gdiff
 :JumpToLastLocation "let b:pos = line('''\"') | if b:pos && b:pos <= line('$') | exe b:pos | endif"
 : TrimTrailingSpace
 : TrimTrailingBlankLines
 : SquashBlankLines
 : TrimBlankLines
 :SaveAndClose "up | bdel"
 : LastWindow
 :Scratchify "setl nobl bt=nofile bh=delete noswf"
 :Scratch "<mods> new +Scratchify"
 :AutoWinHeight "silent exe max([min([line('$'), 12]), 1]).'wincmd _'"
 :AutoIndent "silent norm gg=G`."
 : LspCapabilities
 : GolangCI
 : RunTests
 :PlugUpdate "silent exe '! cd' stdpath('config').' && git submodule foreach git pull'"
 :JQ {:cmd "<line1>,<line2>!jq ." :range true}}

