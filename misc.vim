scriptencoding utf-8

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

func! AutoImg()
  if search('<img') > 0 | echom 'Images are already present' | return | endif

  let l:jpgs = systemlist('ls ' . expand('%:h') . '/*.jpg')
  if len(l:jpgs) ==# 0 || match(l:jpgs[0], 'No such file') > -1
    echom 'There are no images'
    return
  endif

  echom l:jpgs

  " TODO:
  " 1✓ see if there are images in file, if yes, abort
  " 2. call reimg, respecging 1,2,.. .jpg sorting order
  " 3. call jsame (call imagemagik directly)
  " 4. trim spaces around/inside header if needed
  " 5. insert top image
  " 6. insert rest of images at the bottom
  " 7. save
  " 8. move all files to parent folder
  " 9. remove current folder & close
endf

func! CsvCol(colnr)
  if a:colnr > 1
    let n = a:colnr - 1
    exe 'match Keyword /^\([^,|]*[,|]\)\{'.n.'}\zs[^,|]*/'
    exe 'norm! 0'.n.'f,'
  elseif a:colnr == 1
    match Keyword /^[^,]*/ | norm! 0
  else
    match
  endif
endf

com! -count=1 Img    call Img(<count>)
com! -count=1 AllImg exe 'Img' | exe 'norm Go' | call Img(<count>-1)
com! Date            exe 'norm odata:  ' . strftime('%F %T %z')
com! RO              setl spell spelllang=ro
com! -nargs=1 CsvCol call CsvCol(<args>)
com! ArticoleNoi     silent! n `git ls-files -mo content/articole`
com! AutoImg         silent! call AutoImg()
com! WordWrap        setl formatoptions+=w tw=200 | norm gggqG

aug Misc | au!
  au BufEnter */articole/**/*.txt setl ft=markdown spell spelllang=ro
  au BufWritePre */articole/**/*.txt,*/Downloads/**/*.txt WordWrap
aug END

nno <silent> <leader>i <Cmd>Img<CR>
nno <silent> <leader>d <Cmd>Date<CR>
nno <silent> <C-\>     <Cmd>WordWrap<CR><bar><Cmd>w<CR><bar><Cmd>let $VIM_DIR=expand('%:p:h')<CR><Cmd>Term<CR>i<CR>cd "$VIM_DIR" && reimg && jsame && mv * .. && exit<CR><bar><Cmd>q
nno <silent> <F12>m    <Cmd>vs ~/.config/nvim/misc.vim<CR>
