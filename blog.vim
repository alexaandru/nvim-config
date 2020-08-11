scriptencoding utf-8

" Some blog helper functions to aid with adding images, etc.
" Highly specific, meant to work in tandem with my custom static site generator.

func! Img(...)
  if !exists('b:img') | let b:img = 0 | endif
  let l:count = get(a:, 1, 1)
  let l:stop = b:img + l:count

  while b:img < l:stop
    let b:img += 1
    exe 'norm o<img src="/images'.strpart(@%, 7, len(@%) - 7 - 4).'_'.b:img.'.jpg">'
  endw
endf

func! ImgCount()
  let s:prefix = 'content/articole'
  if @%[:len(s:prefix)-1] !=# s:prefix | return 0 | endif

  let s:count = 0
  for s:jpg in glob('content/images/'.@%[8:len(@%)-5].'_*.jpg', 0, 1)
    if s:jpg !~ '_small\d\+.jpg' | let s:count += 1 | endif
  endfor | return s:count
endf

func! AutoImg()
  let [b:img, b:count] = [0, ImgCount()]
  if !b:count | return | endif

  if search('<img') | echom 'ERROR: Images already present, aborted!' | return | endif

  TrimTrailingSpace | TrimTrailingBlankLines

  /-------/1

  call Img() | exe 'norm Go' | call Img(b:count-1)
  norm gg0
endf

func! AutoFB()
  1
  if !search('^foto:', 'n', '^---$') | return | endif
  if search('^foto:\s*Facebook', 'n', '^---$') | return | endif
  2,/^---$/s/^foto:\s*\(.*\)/foto:  Facebook \1/ | nohl
endf

com! -bar -count=1 Img call Img(<count>)
com! -bar          AutoImg call AutoImg()
com!               AutoDate 1 | if !search('^data:', 'n', '^---$') | Date | endif
com! -bar          AutoFB call AutoFB()
com! -bar          Date exe 'norm odata:  '.strftime('%F %T %z')
com! -bar          RO setl spell spelllang=ro
com! -bar          ArticoleNoi silent! n `git ls-files -mo content/articole`
com!               AA ArticoleNoi | argdo AutoImg | up
com!               WordWrap exe 'setl formatoptions+=w tw=200' | exe 'g/ ./ norm gqq' | nohl
com! -bar          TrimLeadingBlankLines exe '1,/---/-1s/^\n//e | nohl'
com!               TrimAll TrimLeadingBlankLines | TrimLeadingBlankLines | TrimTrailingSpace |
      \              TrimTrailingBlankLines | SquashBlankLines | WordWrap
com!               PrepArt exe 'TrimAll' | exe 'AutoDate' | AutoFB | up
com! -bar          PrepArts argdo PrepArt

aug Misc | au!
  au BufEnter */articole/**/*.txt,*/Downloads/**/*.txt setl ft=markdown spell spelllang=ro
  au BufWritePre */articole/**/*.txt,*/Downloads/**/*.txt TrimAll
aug END

nno <silent> <Leader>a <Cmd>AutoImg<CR>
nno <silent> <Leader>i <Cmd>Img<CR>
nno <silent> <Leader>d <Cmd>Date<CR>
nno <silent> <C-\>     <Cmd>w<CR><bar><Cmd>let $VIM_DIR=expand('%:p:h')<CR><Cmd>Term<CR>cd "$VIM_DIR" && reimg && jsame && mv * .. && exit<CR>
nno <silent> <F12>b    <Cmd>vs ~/.config/nvim/blog.vim<CR>
