" Nothing interesting here, these are very custom/specific
" functions/mappings that I use for some personal projects.

func! CurImg()
  set paste

  if exists('b:img') | let b:img = b:img + 1
  else | let b:img = 1
  endif

  exe 'norm o<img src="/images' . strpart(@%, 7, len(@%) - 7 - 4) . '_' . b:img . '.jpg">'
endf

func! CurDate()
  set paste
  exe 'norm odata:  ' . strftime('%F %T %z')
endf

func! CSVH(colnr)
  if a:colnr > 1
    let n = a:colnr - 1
    exe 'match Keyword /^\([^,|]*[,|]\)\{'.n.'}\zs[^,|]*/'
    "exe 'match Keyword /^\([^,]*,\)\{'.n.'}\zs[^,]*/'
    exe 'normal! 0'.n.'f,'
  elseif a:colnr == 1
    match Keyword /^[^,]*/ | norm! 0
  else
    match
  endif
endf


com! RO setl spell spelllang=ro
com! -nargs=1 Csv :call CSVH(<args>)

au! A BufEnter */articole/**/*.txt setl ft=markdown spell spelllang=ro

nno <silent> <leader>i :call CurImg()<CR>
nno <silent> <leader>d :call CurDate()<CR>
nno <silent> <C-\>     <cmd>RemoveTrailingSpace<CR><bar>:w<CR><bar>:let $VIM_DIR=expand('%:p:h')<CR>:T<CR>i<CR>cd "$VIM_DIR" && reimg && jsame && mv * .. && exit<CR><bar>:q
nno <silent> <F12>m    <Cmd>vs ~/.config/nvim/misc.vim<CR>
