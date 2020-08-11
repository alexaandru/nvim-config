scriptencoding utf-8

" Experimental stuff goes in here.

func! ListConfigs(A, L, P)
  let l:configs = map(glob(stdpath('config').'/*.{vim,lua}', 0, 1), {_,v -> fnamemodify(v, ":t")})
  return sort(filter(l:configs, {_,v -> fnamemodify(v, ':r') =~ a:A}))
endf

func! Cfg(...)
  let l:file = 'init.vim' | if a:1 !=# '' | let l:file = a:1 | endif
  exe 'n '.stdpath('config').'/'.l:file
endf

com! -bar -count=0 CC silent setl cc=<count>
com! -nargs=? -bar -complete=customlist,ListConfigs Cfg call Cfg(<q-args>)

nno <silent> <F11>     <Cmd>exe 'CC'..col('.')<CR>
nno <silent> <F12>x    <Cmd>vs ~/.config/nvim/exp.vim<CR>
