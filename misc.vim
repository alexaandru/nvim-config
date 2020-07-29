" Nothing interesting here, these are very custom/specific
" functions/mappings that I use for some personal projects.

func! Img(...)
  if !exists('b:img') | let b:img = 0 | endif

  let l:count = get(a:, 1, 1)
  let l:stop = b:img + l:count

  while b:img < l:stop
    let b:img += 1
    exe 'norm o<img src="/images' . strpart(@%, 7, len(@%) - 7 - 4) . '_' . b:img . '.jpg">'
  endw
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


com! -count=1 Img call Img(<count>)
com! Date         exe 'norm odata:  ' . strftime('%F %T %z')
com! RO           setl spell spelllang=ro
com! -nargs=1 Csv call CSVH(<args>)

au! A BufEnter */articole/**/*.txt setl ft=markdown spell spelllang=ro

nno <silent> <leader>i <Cmd>Img<CR>
nno <silent> <leader>d <Cmd>Date<CR>
nno <silent> <C-\>     <Cmd>RemoveTrailingSpace<CR><bar><Cmd>w<CR><bar><Cmd>let $VIM_DIR=expand('%:p:h')<CR><Cmd>Term<CR>i<CR>cd "$VIM_DIR" && reimg && jsame && mv * .. && exit<CR><bar><Cmd>q
nno <silent> <F12>m    <Cmd>vs ~/.config/nvim/misc.vim<CR>
