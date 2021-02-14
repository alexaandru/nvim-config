scriptencoding utf-8

" Fixes to syntax highlight go here.

colo deus

let s:tr_bg = 'Normal,SignColumn,VertSplit,PreProc,EndOfBuffer,Folded,htmlBold'
for s:i in split(s:tr_bg, ',') | exe 'hi '.s:i.' guibg=NONE' | endfor

hi LspDiagnosticsVirtualTextError       guifg=Red
hi LspDiagnosticsVirtualTextWarning     guifg=Orange
hi LspDiagnosticsVirtualTextInformation guifg=Pink
hi LspDiagnosticsVirtualTextHint        guifg=Green

hi LspDiagnosticsSignError       guifg=Red
hi LspDiagnosticsSignWarning     guifg=Orange
hi LspDiagnosticsSignInformation guifg=Pink
hi LspDiagnosticsSignHint        guifg=Green

"hi Type      gui=NONE
"hi Statement gui=NONE
hi StatusLineNC gui=NONE guibg=#222222
hi EndOfBuffer               guifg=#992277

sig define LspDiagnosticsSignError       text=⚡ texthl=LspDiagnosticsSignError
sig define LspDiagnosticsSignWarning     text=w  texthl=LspDiagnosticsSignWarning
sig define LspDiagnosticsSignInformation text=i  texthl=LspDiagnosticsSignInformation
sig define LspDiagnosticsSignHint        text=💡 texthl=LspDiagnosticsSignHint

nno          <Leader>c <Cmd>so $VIMRUNTIME/syntax/hitest.vim<CR>
nno <silent> <F12>c    <Cmd>Cfg color.vim<CR>

" Tools & tips for colorscheme editing
" https://github.com/lifepillar/vim-colortemplate
" https://speakerdeck.com/cocopon/creating-your-lovely-color-scheme?slide=127
