scriptencoding utf-8

" Misc, experimental, WIP stuff goes in here.
" You probably don't want to copy this one :-)

func! Img(...)
  if !exists('b:img') | let b:img = 0 | endif

  let l:count = get(a:, 1, 1)
  let l:stop = b:img + l:count

  while b:img < l:stop
    let b:img += 1
    exe 'norm o<img src="/images'.strpart(@%, 7, len(@%) - 7 - 4).'_'.b:img.'.jpg">'
  endw
endf

func! WIPAutoImg()
  if search('<img') > 0 | echom 'Images are already present' | return | endif

  let l:jpgs = systemlist('ls '.expand('%:h').'/*.jpg')
  if len(l:jpgs) ==# 0 || match(l:jpgs[0], 'No such file') > -1
    echom 'There are no images'
    return
  endif

  echom l:jpgs
endf

com! -bar -count=1 Img call Img(<count>)
com! -count=1      AllImg exe 'Img' | exe 'norm Go' | call Img(<count>-1)
com!               AutoImg let [b:img, b:count] = [0, expand('<cword>')] | exe 'norm D' | exe b:count.'AllImg'
com! -bar          Date exe 'norm odata:  '.strftime('%F %T %z')
com! -bar          RO setl spell spelllang=ro
com! -bar          ArticoleNoi silent! n `git ls-files -mo content/articole`
com!               WordWrap exe 'setl formatoptions+=w tw=200' | exe 'g/ ./ norm gqq' | nohl
com! -bar -count=0 CC silent setl cc=<count>

aug Misc | au!
  au BufEnter */articole/**/*.txt,*/Downloads/**/*.txt setl ft=markdown spell spelllang=ro
  au BufWritePre */articole/**/*.txt,*/Downloads/**/*.txt WordWrap
aug END

nno <silent> <Leader>a <Cmd>AutoImg<CR>
nno <silent> <Leader>i <Cmd>Img<CR>
nno <silent> <Leader>d <Cmd>Date<CR>
nno <silent> <C-\>     <Cmd>WordWrap<CR><bar><Cmd>w<CR><bar><Cmd>let $VIM_DIR=expand('%:p:h')<CR><Cmd>Term<CR>i<CR>cd "$VIM_DIR" && reimg && jsame && mv * .. && exit<CR><bar><Cmd>q
nno <silent> <F11>     <Cmd>exe 'CC'..col('.')<CR>
nno <silent> <F12>m    <Cmd>vs ~/.config/nvim/misc.vim<CR>
