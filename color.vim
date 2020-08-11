scriptencoding utf-8

colo srcery "onedark iceberg slate desert gruvbox8

let s:tr_bg = 'Normal,SignColumn,VertSplit,PreProc,EndOfBuffer,Folded,htmlBold'
for s:i in split(s:tr_bg, ',') | exe 'hi '.s:i.' guibg=NONE' | endfor

hi LspDiagnosticsError       guifg=Red
hi LspDiagnosticsWarning     guifg=Orange
hi LspDiagnosticsInformation guifg=Pink
hi LspDiagnosticsHint        guifg=Green

"hi Type      gui=NONE
"hi Statement gui=NONE
hi StatusLineNC gui=NONE guibg=NONE

nno          <Leader>c <Cmd>so $VIMRUNTIME/syntax/hitest.vim<CR>
nno <silent> <F12>c    <Cmd>Cfg color.vim<CR>

" Tools & tips for colorscheme editing
" https://github.com/lifepillar/vim-colortemplate
" https://speakerdeck.com/cocopon/creating-your-lovely-color-scheme?slide=127
