scriptencoding utf-8

call plug#begin(stdpath('data') . '/plugged')
Plug 'hashivim/vim-terraform'
"Plug 'iamcco/markdown-preview.nvim', {'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
Plug 'lifepillar/vim-gruvbox8'
Plug 'liuchengxu/vista.vim'
Plug 'neovim/nvim-lsp'
Plug 'norcalli/nvim-colorizer.lua'
"Plug 'nvim-lua/lsp-status.nvim'
Plug 'nvim-lua/completion-nvim'
"Plug 'nvim-lua/diagnostic-nvim'
"Plug 'nvim-treesitter/nvim-treesitter'
"Plug 'leafOfTree/vim-vue-plugin'
call plug#end()

exe 'luafile' stdpath('config') . '/init.lua'

set clipboard+=unnamedplus
set completeopt=menu,noselect,noinsert
set expandtab
set foldmethod=indent
set ignorecase
set inccommand=nosplit
set laststatus=0
set lazyredraw
set mouse=a
set mousemodel=extend
set noshowcmd
set noshowmode
set nostartofline
set nowrap
set omnifunc=v:lua.vim.lsp.omnifunc
set path=**
set shell=bash
set shiftwidth=4
set signcolumn=yes:2
set smartcase
set smartindent
set splitbelow
set splitright
set tabstop=4
set tags=
set termguicolors
set title
set updatetime=500
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
let g:vista_icon_indent = ['╰─▸ ', '├─▸ ']
let g:vista_default_executive = 'nvim_lsp'
let g:vista#renderer#enable_icon = 1
let g:vista#renderer#icons = {'function': 'λ', 'method': 'θ', 'field': '•', 'struct': '∫',
                           \  'variable': '⍺', 'constant': 'π', 'property': '•'}
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

colorscheme gruvbox8

hi LspDiagnosticsError       guifg=Red
hi LspDiagnosticsWarning     guifg=Orange
hi LspDiagnosticsInformation guifg=Pink
hi LspDiagnosticsHint        guifg=Green
hi Folded                    guibg=NONE

augroup A
  au!
augroup END

au A BufEnter * call LastWindow()
au A BufEnter * if &buftype == 'terminal' | :startinsert | endif
au A BufEnter * lua require'completion'.on_attach()
"au A BufEnter * lua require'diagnostic'.on_attach()
au A BufWritePre *.go lua GoOrgImports()
au A BufWritePre * RemoveTrailingSpace
au A BufWritePre * RemoveTrailingBlankLines
au A TextYankPost * silent! lua require'vim.highlight'.on_yank()
au A QuickFixCmdPost [^l]* nested cwindow
au A QuickFixCmdPost    l* nested lwindow
au A TermClose * :q
au A FileType * norm zR
au A FileType gitcommit,asciidoc,markdown setl spell
au A FileType vim setl ts=2 sw=2
     \ makeprg=vint\ --enable-neovim\ %
au A BufWritePost init.vim source % " automatically reload when changing
au A FileType javascript setl makeprg=npm\ run\ lint
au A FileType terraform setl
     \ makeprg=\(terraform\ validate\ -no-color\ &&\ for\ i\ in\ $\(find\ -iname\ '*.tf'\\\|xargs\ dirname\\\|sort\ -u\\\|paste\ -s\);\ do\ tflint\ $i;\ done\)
au A BufWritePost *.tf Terrafmt
au A FileType go setl ts=4 sw=4 noexpandtab foldmethod=syntax
     \ makeprg=(go\ build\ ./...\ &&\ go\ vet\ ./...)

comm! -nargs=* T split | resize 10 | term <args>
comm! Make silent make | echo "    make ✓" | sleep 1200ms | echo
comm! Terrafmt  :exe 'silent !terraform fmt %' | :e
comm! RemoveTrailingSpace :norm m':%s/[<Space><Tab><C-v><C-m>]\+$//e<NL>''
comm! RemoveTrailingBlankLines :%s#\($\n\s*\)\+\%$##e
comm! SaveAndClose :exe 'w' | :bdel

func! LastWindow()
  if &buftype ==# 'quickfix' && winbufnr(2) ==# -1 | quit! | endif
endf

" Buffer utils
nnoremap gb                 :ls<CR>:b<Space>
nnoremap db                 :%bd<bar>e#<CR>
" Builtin LSP
nnoremap <silent> gd        <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> <c-]>     <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> K         <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD        <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> <c-k>     <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> 1gD       <cmd>lua vim.lsp.buf.type_definition()<CR>
nnoremap <silent> gr        <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> g0        <cmd>lua vim.lsp.buf.document_symbol()<CR>
nnoremap <silent> gW        <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
" Various
nnoremap <silent> <C-n>     :let $VIM_DIR=expand('%:p:h')<CR>:T<CR>i<CR>cd "$VIM_DIR"<CR>clear<CR>
nnoremap <silent> <F3>      :only<CR>
nnoremap <silent> <F2>      :lua vim.lsp.buf.rename()<CR>
nnoremap <silent> <F5>      :silent make<CR><bar>:echo "    make ✓"<CR><bar>:sleep 1200ms<CR><bar>:echo<CR>
"nnoremap <silent> <F5>      :Make<CR><CR>
nnoremap <silent> <F6>      :cgetexpr system('golangci-vim '.expand('%'))<CR><bar>:echo "    lint ✓"<CR><bar>:sleep 1200ms<CR><bar>:echo<CR>
nnoremap <silent> <F7>      :cgetexpr system('golangci-lint run --print-issued-lines=0 ./...')<CR><bar>:echo "    lint ✓"<CR><bar>:sleep 1200ms<CR><bar>:echo<CR>
nnoremap <silent> <F1>      :Vista!!<CR>
nnoremap <silent> <Space>   @=((foldclosed(line('.')) < 0) ? 'zC' : 'zO')<CR>
nnoremap <silent> <C-Right> :cnext<CR>
nnoremap <silent> <C-Left>  :cprev<CR>
nnoremap <silent> <F12>     :vs ~/.config/nvim/init.vim<CR>
nnoremap <silent> <F12>l    :vs ~/.config/nvim/init.lua<CR>
nnoremap <silent> <Leader>w <cmd>SaveAndClose<CR>
" Snippets
nnoremap <silent>           \html :-1read ~/.local/share/nvim/snippets/skeleton.html<CR>3jwf>a
" Easier windows resize
nnoremap -                  <C-W>-
nnoremap +                  <C-W>+
nnoremap <                  <C-W>>
nnoremap >                  <C-W><
" Saner wildmenu navigation
cnoremap <expr> <Up>        wildmenumode() ? "\<Left>"     : "\<Up>"
cnoremap <expr> <Down>      wildmenumode() ? "\<Right>"    : "\<Down>"
cnoremap <expr> <Left>      wildmenumode() ? "\<Up>"       : "\<Left>"
cnoremap <expr> <Right>     wildmenumode() ? "\<BS>\<C-Z>" : "\<Right>"
" Auto-pairs
inoremap '                  ''<Left>
inoremap (                  ()<Left>
inoremap {                  {}<Left>

exe 'source' stdpath('config') . '/misc.vim'