(local cfgdir (vim.fn.stdpath :config))

[(string.format "-nargs=1 -bar -complete=customlist,v:lua.CfgComplete Cfg e %s/<args>"
                cfgdir)
 "-nargs=1 Grep silent grep <args>"
 "-nargs=* Term 12split | term <args>"
 "     LoadLocalCfg if filereadable('.nvimrc') | so .nvimrc | endif"
 "-bar SetProjRoot let w:proj_root = fnamemodify(finddir('.git/..', expand('%:p:h').';'), ':p')"
 "-bar CdProjRoot SetProjRoot | cd `=w:proj_root`"
 "     Gdiff SetProjRoot | exe 'silent !cd '.w:proj_root.' && git show HEAD^:'.luaeval('ProjRelativePath()').' > /tmp/gdiff' | diffs /tmp/gdiff"
 "     JumpToLastLocation let b:pos = line('''\"') | if b:pos && b:pos <= line('$') | exe b:pos | endif"
 "-bar -range=% TrimTrailingSpace lua TrimTrailingSpace(<line1>,<line2>)"
 "-bar -range=% TrimTrailingBlankLines lua TrimTrailingBlankLines(<line1>,<line2>)"
 "-bar -range=% SquashBlankLines lua SquashBlankLines(<line1>,<line2>)"
 "-bar -range=% TrimBlankLines lua TrimBlankLines(<line1>,<line2>)"
 "     SaveAndClose up | bdel"
 "     LastWindow if (&buftype ==# 'quickfix' || &buftype ==# 'terminal' || &buftype ==# 'nofile' || &filetype ==# 'netrw') && winbufnr(2) ==# -1 | q | endif"
 "-bar Scratchify setl nobl bt=nofile bh=delete noswf"
 "-bar Scratch <mods> new +Scratchify"
 "-bar AutoWinHeight silent exe max([min([line('$'), 12]), 1]).'wincmd _'"
 "-bar AutoIndent silent norm gg=G`."
 "-bar LspCapabilities lua LspCapabilities()"
 "-bar PlugUpdate silent exe '! cd' stdpath('config').' && git submodule foreach git pull'"
 "-bar -range JQ <line1>,<line2>!jq ."]

