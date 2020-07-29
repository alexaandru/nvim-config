scriptencoding utf-8

call plug#begin(stdpath('data') . '/plugged')
Plug 'neovim/nvim-lsp'
Plug 'lifepillar/vim-gruvbox8'
Plug 'hashivim/vim-terraform'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'nvim-lua/completion-nvim'
Plug 'AndrewRadev/tagalong.vim'
call plug#end()

exe 'luafile' stdpath('config') . '/init.lua'

set clipboard+=unnamedplus
set complete+=kspell completeopt=menuone,noselect,noinsert
set diffopt+=algorithm:patience,indent-heuristic,vertical
set expandtab
set foldmethod=indent foldlevelstart=1000
set grepprg=internal
set icon iconstring=nvim
set ignorecase
set inccommand=nosplit
set laststatus=0
set lazyredraw
set mouse=a mousemodel=extend
set noshowcmd
set noshowmode
set nostartofline
set nowrap
set omnifunc=v:lua.vim.lsp.omnifunc
set path=**
set shell=bash
set shortmess+=c
set signcolumn=yes:2
set smartcase smartindent
set splitbelow splitright
set tags=
set termguicolors
set title titlestring=\{\ %n\ \}\ %<%f%=%{Modified('+','')}
set wildcharm=<C-Z>
set wildignore+=.git,node_modules,*.cache,*.dat,*.idx,*.csv,*.tsv

" needs termguicolors to be set 1st
lua require'colorizer'.setup()

let $GOFLAGS='-tags=development'
let g:loaded_python_provider = 0
let g:loaded_python3_provider = 0
let g:loaded_node_provider = 0
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0
let g:netrw_banner = 0
let g:netrw_liststyle = 1
let g:netrw_browse_split = 4
let g:netrw_preview = 1
let g:netrw_altv = 1
let g:netrw_list_hide = '^\.[a-zA-Z].*,^\./$'
let g:netrw_hide = 1
let g:netrw_winsize = 15
let g:gruvbox_filetype_hi_groups = 1
let g:gruvbox_transp_bg = 1
let g:tagalong_additional_filetypes = ['vue']

colorscheme gruvbox8

hi LspDiagnosticsError       guifg=Red
hi LspDiagnosticsWarning     guifg=Orange
hi LspDiagnosticsInformation guifg=Pink
hi LspDiagnosticsHint        guifg=Green
hi Folded                    guibg=NONE

func! Modified(modified, not_modified)
  if &modified | return a:modified | else | return a:not_modified | endif
endf

func! GolangCI(...)
  let l:scope = get(a:, 1, '.')
  if l:scope ==# '%' | let l:scope = expand('%') | endif

  let l:only = get(a:, 2, '')
  if l:only !=# '' | let l:only = '--exclude-use-default=0 --no-config --disable-all --enable ' .. l:only | endif

  let l:lst = systemlist('golangci-lint run --print-issued-lines=0 '.. l:only ..' ./...')
  cgete filter(l:lst, 'v:val =~ "^'.. l:scope ..'"')
endf

com! -nargs=* Term split | resize 12 | term <args>
com! Make silent make | redraw | echo '    MAKE'
com! -nargs=* -complete=file_in_path GolangCI call GolangCI(<f-args>) | echo '    LINT'
com! Gdiff exe 'silent !git show HEAD^:% > /tmp/gdiff' | diffs /tmp/gdiff
com! Terrafmt exe 'silent !terraform fmt %' | e
com! RemoveTrailingSpace norm m':%s/[<Space><Tab><C-v><C-m>]\+$//e<NL>''
com! RemoveTrailingBlankLines %s#\($\n\s*\)\+\%$##e
com! SaveAndClose w | bdel
com! LastWindow if &buftype ==# 'quickfix' && winbufnr(2) ==# -1 | q | endif
com! Scratchify setl nobl bt=nofile bh=delete noswapfile
com! Scratch <mods> new +Scratchify
com! AutoWinHeight silent exe max([min([line('$'), 12]), 1]) . 'wincmd _'
com! AutoIndent silent norm gg=G`.
com! LspCapabilities lua print(vim.inspect(vim.lsp.buf_get_clients()[1].server_capabilities))
com! -nargs=1 Grep grep /<args>/jg `git ls-files`

aug A
  au!
aug end

au A BufEnter * LastWindow
au A BufEnter * if &buftype == 'terminal' | star | endif
au A BufEnter * lua require'completion'.on_attach()
au A BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "norm! g'\"" | endif
au A BufWritePre * RemoveTrailingSpace
au A BufWritePre * RemoveTrailingBlankLines
au A TextYankPost * silent! lua require'vim.highlight'.on_yank()
au A TermClose * q
au A BufRead,BufNewFile go.mod set ft=gomod
au A BufWritePost,FileWritePost go.mod silent! make | e
au A BufWritePre *.go lua GoOrgImports(); vim.lsp.buf.formatting_sync()
au A BufWritePre *.vim,*.lua AutoIndent
au A QuickFixCmdPost [^l]* nested cw
au A QuickFixCmdPost    l* nested lw
au A FileType qf AutoWinHeight
au A FileType gitcommit,asciidoc,markdown setl spell spelllang=en_us
au A FileType lua setl ts=2 sw=2 sts=2
au A FileType vim setl ts=2 sw=2 sts=2
      \ makeprg=vint\ --enable-neovim\ %
au A BufWritePost init.vim,init.lua,misc.vim so $MYVIMRC
au A FileType javascript setl makeprg=npm\ run\ lint
au A FileType terraform setl
      \ makeprg=\(terraform\ validate\ -no-color\ &&\ for\ i\ in\ $\(find\ -iname\ '*.tf'\\\|xargs\ dirname\\\|sort\ -u\\\|paste\ -s\);\ do\ tflint\ $i;\ done\)
au A BufWritePost *.tf Terrafmt
au A FileType go setl ts=4 sw=4 noexpandtab foldmethod=syntax
      \ makeprg=(go\ build\ ./...\ &&\ go\ vet\ ./...)
au A FileType gomod setl
      \ makeprg=go\ mod\ tidy

nno gb                 <Cmd>ls<CR>:b<Space>
nno db                 <Cmd>%bd<bar>e#<CR>
nno <silent> gd        <Cmd>lua vim.lsp.buf.declaration()<CR>
nno <silent> <c-]>     <Cmd>lua vim.lsp.buf.definition()<CR>
nno <silent> <F1>      <Cmd>lua vim.lsp.buf.hover()<CR>
nno <silent> gD        <Cmd>lua vim.lsp.buf.implementation()<CR>
nno <silent> <c-k>     <Cmd>lua vim.lsp.buf.signature_help()<CR>
nno <silent> 1gD       <Cmd>lua vim.lsp.buf.type_definition()<CR>
nno <silent> gr        <Cmd>lua vim.lsp.buf.references()<CR>
nno <silent> g0        <Cmd>lua vim.lsp.buf.document_symbol()<CR>
nno <silent> gW        <Cmd>lua vim.lsp.buf.workspace_symbol()<CR>
nno <silent> <F2>      <Cmd>lua vim.lsp.buf.rename()<CR>
nno <silent> <C-n>     <Cmd>let $VIM_DIR=expand('%:p:h')<CR><Cmd>Term<CR>i<CR>cd "$VIM_DIR"<CR>clear<CR>
nno <silent> <F3>      <Cmd>only<CR>
nno <silent> <F5>      <Cmd>Make<CR>
nno <silent> <F6>      <Cmd>GolangCI<CR>
nno <silent> <F6>%     <Cmd>GolangCI %<CR>
nno <silent> <F8>      <Cmd>Gdiff<CR>
nno <silent> <C-Right> <Cmd>cnext<CR>
nno <silent> <C-Left>  <Cmd>cprev<CR>
nno <silent> <F12>     <Cmd>vs ~/.config/nvim/init.vim<CR>
nno <silent> <F12>l    <Cmd>vs ~/.config/nvim/init.lua<CR>
nno <silent> <Leader>w <Cmd>SaveAndClose<CR>
nno <silent> <Space>   @=((foldclosed(line('.')) < 0) ? 'zC' : 'zO')<CR>
nno <silent>           \html :-1read ~/.local/share/nvim/snippets/skeleton.html<CR>3jwf>a
nno -                  <C-W>-
nno +                  <C-W>+
nno <                  <C-W>>
nno >                  <C-W><
cno <expr>   <Up>      wildmenumode() ? "\<Left>"     : "\<Up>"
cno <expr>   <Down>    wildmenumode() ? "\<Right>"    : "\<Down>"
cno <expr>   <Left>    wildmenumode() ? "\<Up>"       : "\<Left>"
cno <expr>   <Right>   wildmenumode() ? "\<BS>\<C-Z>" : "\<Right>"
ino <silent> <F2>      <C-x>s
ino '                  ''<Left>
ino (                  ()<Left>
ino {                  {}<Left>

exe 'source' stdpath('config') . '/misc.vim'
