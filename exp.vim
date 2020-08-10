scriptencoding utf-8

" Experimental stuff goes in here.

func! ListConfigs(A, L, P)
  let l:configs = map(glob(stdpath('config').'/*.{vim,lua}', 0, 1), {i,v -> fnamemodify(v, ":t")})
  return sort(filter(l:configs, 'v:val =~ "^'.a:A.'"'))
endf

func! Cfg(...)
  let l:file = get(a:, 1, 'init.vim')
  exe 'n '.stdpath('config').'/'.l:file
endf

com! -bar -count=0 CC silent setl cc=<count>
com! -nargs=? -bar -complete=customlist,ListConfigs Cfg call Cfg(<q-args>)

nno <silent> <F11>     <Cmd>exe 'CC'..col('.')<CR>
nno <silent> <F12>x    <Cmd>vs ~/.config/nvim/exp.vim<CR>
