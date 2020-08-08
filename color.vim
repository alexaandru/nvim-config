scriptencoding utf-8

let g:gruvbox_filetype_hi_groups = 1
let g:gruvbox_transp_bg = 1
let g:onedark_hide_endofbuffer = 1
let g:onedark_terminal_italics = 1
let s:tr_bg = 'Normal,SignColumn,VertSplit,PreProc,EndOfBuffer,Folded,htmlBold'

colo onedark "iceberg slate desert gruvbox8

for s:i in split(s:tr_bg, ',') | exe 'hi '.s:i.' guibg=NONE' | endfor

hi LspDiagnosticsError       guifg=Red
hi LspDiagnosticsWarning     guifg=Orange
hi LspDiagnosticsInformation guifg=Pink
hi LspDiagnosticsHint        guifg=Green

hi Type      gui=NONE
hi Statement gui=NONE

nno          <Leader>c <Cmd>so $VIMRUNTIME/syntax/hitest.vim<CR>
nno <silent> <F12>c    <Cmd>vs ~/.config/nvim/color.vim<CR>
