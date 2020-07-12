func! CurImg()
  set paste

  if exists('b:img')
    let b:img = b:img + 1
  else
    let b:img = 1
  endif

  exe 'normal o<img src="/images' . strpart(@%, 7, len(@%) - 7 - 4) . '_' . b:img . '.jpg">'
endf

func! CurDate()
  set paste
  exe 'normal odata:  ' . strftime('%F %T %z')
endf

nnoremap <silent> <leader>i :call CurImg()<CR>
nnoremap <silent> <leader>d :call CurDate()<CR>
nnoremap <silent> <C-\>     <cmd>RemoveTrailingSpace<CR><bar>:w<CR><bar>:let $VIM_DIR=expand('%:p:h')<CR>:T<CR>i<CR>cd "$VIM_DIR" && reimg && jsame && mv * .. && exit<CR><bar>:q
