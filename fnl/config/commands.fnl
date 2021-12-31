;; Format is: {CommandName CommandSpec, ...}
;; where CommandSpec is either String, Table or Lua function.
;;
;; If it is Table, then the command itself must be passed in .cmd, the
;; rest of CommandSpec is treated as arguments to command.
;;
;; The -bar argument is going to be filled in automatically, do not pass that;
;; The -range bar may be omitted: if <line1> is present in command, then
;;      range is set automaticall to %.

(local withConfig #(string.format $ (vim.fn.stdpath :config)))

{:Cfg {:cmd (withConfig "e %s/fnl/<args>") :complete "customlist,v:lua.CfgComplete" :nargs 1}
 :Grep {:cmd "silent grep <args>" :nargs 1}
 :Term {:cmd "12split | term <args>" :nargs "*"}
 :LoadLocalCfg "if filereadable('.nvimrc') | so .nvimrc | endif"
 :SetProjRoot "let w:proj_root = fnamemodify(finddir('.git/..', expand('%:p:h').';'), ':p')"
 :CdProjRoot "SetProjRoot | cd `=w:proj_root`"
 :Gdiff "SetProjRoot | exe 'silent !cd '.w:proj_root.' && git show HEAD^:'.luaeval('ProjRelativePath()').' > /tmp/gdiff' | diffs /tmp/gdiff"
 :JumpToLastLocation "let b:pos = line('''\"') | if b:pos && b:pos <= line('$') | exe b:pos | endif"
 :TrimTrailingSpace "lua TrimTrailingSpace(<line1>,<line2>)"
 :TrimTrailingBlankLines "lua TrimTrailingBlankLines(<line1>,<line2>)"
 :SquashBlankLines "lua SquashBlankLines(<line1>,<line2>)"
 :TrimBlankLines "lua TrimBlankLines(<line1>,<line2>)"
 :SaveAndClose "up | bdel"
 :LastWindow "if (&buftype ==# 'quickfix' || &buftype ==# 'terminal' || &buftype ==# 'nofile' || &filetype ==# 'netrw') && winbufnr(2) ==# -1 | q | endif"
 :Scratchify "setl nobl bt=nofile bh=delete noswf"
 :Scratch "<mods> new +Scratchify"
 :AutoWinHeight "silent exe max([min([line('$'), 12]), 1]).'wincmd _'"
 :AutoIndent "silent norm gg=G`."
 :LspCapabilities "lua LspCapabilities()"
 :PlugUpdate "silent exe '! cd' stdpath('config').' && git submodule foreach git pull'"
 :FnlCompile "lua FnlCompile(<line1>,<line2>)"
 :FnlEval "lua FnlEval(<line1>,<line2>)"
 :JQ {:cmd "<line1>,<line2>!jq ." :range true}}

