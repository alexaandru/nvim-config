scriptencoding utf-8

packadd nvim-lspconfig
packadd nvim-lspupdate
packadd nvim-treesitter
packadd nvim-treesitter-textobjects
packadd nvim-colorizer.lua
packadd nvim-deus
"packadd markdown-preview.nvim
"packadd cfilter

lua require'config'

set autowriteall hidden
set clipboard+=unnamedplus
set complete+=kspell completeopt=menuone,noselect,noinsert
set diffopt+=algorithm:patience,indent-heuristic,vertical
set expandtab
set grepprg=git\ grep\ -n
set icon iconstring=nvim
set ignorecase
set inccommand=nosplit
set laststatus=0
set lazyredraw
set mouse=a mousemodel=extend
set noshowcmd noshowmode nostartofline nowrap
set omnifunc=v:lua.vim.lsp.omnifunc
set path=**
set shell=bash
set shortmess+=c
set signcolumn=yes:2
set smartcase smartindent
set splitbelow splitright
set termguicolors
set title titlestring=🐙\ \%{get(b:,'git_status','~git')}\ 📚\ %<%f%=%M\ \ 📦\ %{nvim_treesitter#statusline(150)}
set wildcharm=<C-Z>
set wildignore+=*/.git/*,*/node_modules/*
set wildignorecase

let $GOFLAGS='-tags=development'
let g:loaded_python_provider = 0
let g:loaded_python3_provider = 0
let g:loaded_node_provider = 0
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0
let s:makeprg = {
      \ 'go':         '(go build ./... && go vet ./...)',
      \ 'gomod':      'go mod tidy',
      \ 'gosum':      'go mod tidy',
      \ 'vim':        'vint --enable-neovim %',
      \ 'javascript': 'npm run lint',
      \ 'terraform':  '(terraform validate -no-color && for i in $(find -iname ''*.tf''\|xargs dirname\|sort -u\|paste -s); do tflint $i; done)',
      \ 'json':       'jsonlint %',
      \ 'lua':        'luacheck --formatter plain --globals vim -- %',
      \ }

func! GolangCI(...)
  let l:scope = get(a:, 1, '.') | if l:scope ==# '%' | let l:scope = expand('%') | endif
  let l:only = get(a:, 2, '') | if l:only !=# '' | let l:only = '--exclude-use-default=0 --no-config --disable-all --enable '.l:only | endif
  let l:lst = systemlist('golangci-lint run --print-issued-lines=0 '.l:only.' ./...')

  cgete filter(l:lst, 'v:val =~ "^'.l:scope.'"')
endf

func! ProjRelativePath()
  return expand('%:p')[len(b:proj_root):]
endf

func! GitStatus()
  let l:branch = trim(system('git rev-parse --abbrev-ref HEAD 2> /dev/null'), "\n")
  if l:branch ==# '' | return '~git' | endif
  let l:dirty = system('git diff --quiet || echo -n \*')
  let b:git_status = l:branch.l:dirty

  return b:git_status
endf

func! ListConfigs(A, L, P)
  let l:configs = map(glob(stdpath('config').'/*.{vim,lua}', 0, 1), {_,v -> fnamemodify(v, ":t")})
  return sort(filter(l:configs, {_,v -> fnamemodify(v, ':r') =~ a:A}))
endf

func! Cfg(...)
  let l:file = 'init.vim' | if a:1 !=# '' | let l:file = a:1 | endif
  exe 'e '.stdpath('config').'/'.l:file
endf

func! TransparentBG()
  let s:tr_bg = 'Normal,SignColumn,VertSplit,PreProc,EndOfBuffer,Folded,htmlBold'
  for s:i in split(s:tr_bg, ',') | exe 'hi '.s:i.' guibg=NONE' | endfor
endf

com! -bar     Make silent make
com! -bar     SetMake let &makeprg = get(s:makeprg, &filetype, 'make')
com! -nargs=1 Grep silent grep <args>
com! -nargs=* Term split | resize 12 | term <args>
com! -nargs=* -bar -complete=file_in_path GolangCI call GolangCI(<f-args>)
com! -nargs=? -bar -complete=customlist,ListConfigs Cfg call Cfg(<q-args>)
com!          LoadLocalCfg if filereadable('.nvimrc') | so .nvimrc | endif
com! -bar     SetProjRoot let b:proj_root = fnamemodify(finddir('.git/..', expand('%:p:h').';'), ':p')
com! -bar     CdProjRoot SetProjRoot | exe 'cd' b:proj_root
com!          Gdiff SetProjRoot | exe 'silent !cd '.b:proj_root.' && git show HEAD^:'.ProjRelativePath().' > /tmp/gdiff' | diffs /tmp/gdiff
com!          JumpToLastLocation let b:pos = line('''"') | if b:pos && b:pos <= line('$') | exe b:pos | endif
com! -bar     TrimTrailingSpace silent norm m':%s/[<Space><Tab><C-v><C-m>]\+$//e<NL>''
com! -bar     TrimTrailingBlankLines %s#\($\n\s*\)\+\%$##e
com! -bar -range=% SquashBlankLines <line1>,<line2>s/\(\n\)\{3,}/\1\1/e
com! -bar -range=% TrimBlankLines <line1>,<line2>s/\(\n\)\{2,}/\1/e
com!          SaveAndClose up | bdel
com!          LastWindow if (&buftype ==# 'quickfix' || &buftype ==# 'terminal' || &filetype ==# 'netrw')
      \         && winbufnr(2) ==# -1 | q | endif
com! -bar     Scratchify setl nobl bt=nofile bh=delete noswf
com! -bar     Scratch <mods> new +Scratchify
com! -bar     AutoWinHeight silent exe max([min([line('$'), 12]), 1]).'wincmd _'
com! -bar     AutoIndent silent norm gg=G`.
com! -bar     LspCapabilities lua LspCapabilities()
com!          PlugUpdate silent exe '! cd' stdpath('config').'/pack && git submodule update --remote --rebase' | so $MYVIMRC
com! -range   JQ <line1>,<line2>!jq .

aug Setup | au!
  au VimEnter,DirChanged * CdProjRoot | exe 'LoadLocalCfg' | call GitStatus()
  au TextYankPost * silent! lua require'vim.highlight'.on_yank()
  au ColorScheme * call TransparentBG()
  au QuickFixCmdPost [^l]* nested cw
  au QuickFixCmdPost    l* nested lw
  au TermOpen * star
  au TermClose * q
  au FileType qf AutoWinHeight
  au FileType gitcommit,asciidoc,markdown setl spell spl=en_us
  au FileType lua,vim setl ts=2 sw=2 sts=2 fdls=0 fdm=expr fde=nvim_treesitter#foldexpr()
  au FileType go setl ts=4 sw=4 noet fdm=expr fde=nvim_treesitter#foldexpr()
  au BufEnter * SetMake | exe 'ColorizerAttachToBuffer' | LastWindow
  au BufEnter go.mod set ft=gomod
  au BufEnter go.sum set ft=gosum
  au BufReadPost *.go,*.vim,*.lua JumpToLastLocation
  au BufWritePre * TrimTrailingSpace | TrimTrailingBlankLines
  au BufWritePre *.vim AutoIndent
  au BufWritePost ~/.config/nvim/*.{vim,lua} so $MYVIMRC | e
  au BufWritePost,FileWritePost go.mod,go.sum silent! make | e
aug END

nno <silent> gb        <Cmd>ls<CR>:b<Space>
nno <silent> db        <Cmd>%bd<bar>e#<CR>
nno <silent> <C-n>     <Cmd>let $CD=expand('%:p:h')<CR><Cmd>Term<CR>cd "$CD"<CR>clear<CR>
nno <silent> <F3>      <Cmd>only<CR>
nno <silent> <F5>      <Cmd>Make<CR>
nno <silent> <F6>      <Cmd>GolangCI<CR>
nno <silent> <F6>%     <Cmd>GolangCI %<CR>
nno <silent> <F8>      <Cmd>Gdiff<CR>
nno <silent> <M-Right> <Cmd>cnext<CR>
nno <silent> <M-Left>  <Cmd>cprev<CR>
nno <silent> <F12>     <Cmd>Cfg<CR>
nno <silent> <F12>l    <Cmd>Cfg config.lua<CR>
nno <silent> <F12>c    <Cmd>Cfg setup.lua<CR>
nno <silent> <Leader>w <Cmd>SaveAndClose<CR>
nno          <Leader>c <Cmd>so $VIMRUNTIME/syntax/hitest.vim<CR>
nno <silent> <Space>   @=((foldclosed(line('.')) < 0) ? 'zC' : 'zO')<CR>
nno          <C-p>     :find *
cno <expr>   <Up>      wildmenumode() ? "\<Left>"     : "\<Up>"
cno <expr>   <Down>    wildmenumode() ? "\<Right>"    : "\<Down>"
cno <expr>   <Left>    wildmenumode() ? "\<Up>"       : "\<Left>"
cno <expr>   <Right>   wildmenumode() ? "\<BS>\<C-Z>" : "\<Right>"
xno          <Leader>q !jq .<CR>
ino          '         ''<Left>
ino <expr>   <Tab>     luaeval("SmartTabComplete()")
"ino          "         ""<Left>
ino          (         ()<Left>
ino          [         []<Left>
ino          {         {}<Left>

colo deus
colo deus "beats me why I have to call this twice...

hi LspDiagnosticsVirtualTextError       guifg=Red
hi LspDiagnosticsVirtualTextWarning     guifg=Orange
hi LspDiagnosticsVirtualTextInformation guifg=Pink
hi LspDiagnosticsVirtualTextHint        guifg=Green
hi StatusLineNC gui=NONE                guibg=#222222
hi EndOfBuffer                          guifg=#992277

for i in systemlist('ls '.stdpath('config').'/*.vim|grep -v init') | exe 'so' i | endfor
