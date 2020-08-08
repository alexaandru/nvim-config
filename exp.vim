scriptencoding utf-8

" Experimental stuff goes in here.

com! -bar -count=0 CC silent setl cc=<count>

nno <silent> <F11>     <Cmd>exe 'CC'..col('.')<CR>
nno <silent> <F12>x    <Cmd>vs ~/.config/nvim/exp.vim<CR>
