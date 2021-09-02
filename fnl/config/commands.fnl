(local fmt string.format)
(local conf (vim.fn.stdpath :config))

[(fmt "|=1-complete=customlist,v:lua.CfgComplete Cfg e %s/<args>" conf)
 "=1Grep silent grep <args>"
 "=*Term 12split | term <args>"
 "LoadLocalCfg if filereadable('.nvimrc') | so .nvimrc | endif"
 "|SetProjRoot let w:proj_root = fnamemodify(finddir('.git/..', expand('%:p:h').';'), ':p')"
 "CdProjRoot SetProjRoot | cd `=w:proj_root`"
 "Gdiff SetProjRoot | exe 'silent !cd '.w:proj_root.' && git show HEAD^:'.luaeval('ProjRelativePath()').' > /tmp/gdiff' | diffs /tmp/gdiff"
 "JumpToLastLocation let b:pos = line('''\"') | if b:pos && b:pos <= line('$') | exe b:pos | endif"
 "|%TrimTrailingSpace lua TrimTrailingSpace(<line1>,<line2>)"
 "|%TrimTrailingBlankLines lua TrimTrailingBlankLines(<line1>,<line2>)"
 "|%SquashBlankLines lua SquashBlankLines(<line1>,<line2>)"
 "|%TrimBlankLines lua TrimBlankLines(<line1>,<line2>)"
 "SaveAndClose up | bdel"
 "LastWindow if (&buftype ==# 'quickfix' || &buftype ==# 'terminal' || &buftype ==# 'nofile' || &filetype ==# 'netrw') && winbufnr(2) ==# -1 | q | endif"
 "|Scratchify setl nobl bt=nofile bh=delete noswf"
 "|Scratch <mods> new +Scratchify"
 "|AutoWinHeight silent exe max([min([line('$'), 12]), 1]).'wincmd _'"
 "|AutoIndent silent norm gg=G`."
 "|LspCapabilities lua LspCapabilities()"
 "|PlugUpdate silent exe '! cd' stdpath('config').' && git submodule foreach git pull'"
 "|%FnlCompile lua FnlCompile(<line1>,<line2>)"
 "|%FnlEval lua FnlEval(<line1>,<line2>)"
 "|-range JQ <line1>,<line2>!jq ."]

