scriptencoding utf-8

lua require'setup'()

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
let s:tr_bg = 'Normal,SignColumn,VertSplit,PreProc,EndOfBuffer,Folded,htmlBold'
let s:configs = map(glob(stdpath('config').'/*.{vim,lua}', 0, 1), {_,v -> fnamemodify(v, ":t")})
for i in ['python', 'python3', 'node', 'ruby', 'perl']
  let g:['loaded_'.i.'_provider'] = 0
endfor

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

func! CfgList(A, L, P)
  return filter(copy(s:configs), {_,v -> v =~ '^'.a:A})
endf

com! -nargs=1 -bar -complete=customlist,CfgList Cfg e ~/.config/nvim/<args>
com! -nargs=1 Grep silent grep <args>
com! -nargs=* Term 12split | term <args>
com!      LoadLocalCfg if filereadable('.nvimrc') | so .nvimrc | endif
com! -bar SetProjRoot let b:proj_root = fnamemodify(finddir('.git/..', expand('%:p:h').';'), ':p')
com! -bar CdProjRoot SetProjRoot | exe 'cd' b:proj_root
com!      Gdiff SetProjRoot | exe 'silent !cd '.b:proj_root.' && git show HEAD^:'.ProjRelativePath().' > /tmp/gdiff' | diffs /tmp/gdiff
com!      JumpToLastLocation let b:pos = line('''"') | if b:pos && b:pos <= line('$') | exe b:pos | endif
com! -bar TrimTrailingSpace silent norm m':%s/[<Space><Tab><C-v><C-m>]\+$//e<NL>''
com! -bar TrimTrailingBlankLines %s#\($\n\s*\)\+\%$##e
com! -bar -range=% SquashBlankLines <line1>,<line2>s/\(\n\)\{3,}/\1\1/e
com! -bar -range=% TrimBlankLines <line1>,<line2>s/\(\n\)\{2,}/\1/e
com!      SaveAndClose up | bdel
com!      LastWindow if (&buftype ==# 'quickfix' || &buftype ==# 'terminal' || &filetype ==# 'netrw')
      \   && winbufnr(2) ==# -1 | q | endif
com! -bar Scratchify setl nobl bt=nofile bh=delete noswf
com! -bar Scratch <mods> new +Scratchify
com! -bar AutoWinHeight silent exe max([min([line('$'), 12]), 1]).'wincmd _'
com! -bar AutoIndent silent norm gg=G`.
com! -bar LspCapabilities lua require'util'.LspCapabilities()
com!      PlugUpdate silent exe '! cd' stdpath('config').'/pack && git submodule foreach git pull'
com!      TransparentBG for s:i in split(s:tr_bg, ',') | exe 'hi '.s:i.' guibg=NONE' | endfor
com! -range JQ <line1>,<line2>!jq .

aug Setup | au!
  au VimEnter,DirChanged * CdProjRoot | exe 'LoadLocalCfg' | call GitStatus()
  au TextYankPost * silent! lua require'vim.highlight'.on_yank()
  au ColorScheme * TransparentBG
  au QuickFixCmdPost [^l]* nested cw
  au QuickFixCmdPost    l* nested lw
  au TermOpen * star
  au TermClose * q
  au FileType qf AutoWinHeight
  au FileType gitcommit,asciidoc,markdown setl spell spl=en_us
  au FileType lua,vim setl ts=2 sw=2 sts=2 fdls=0 fdm=expr fde=nvim_treesitter#foldexpr()
  au FileType go setl ts=4 sw=4 noet fdm=expr fde=nvim_treesitter#foldexpr()
  au BufEnter * exe 'ColorizerAttachToBuffer' | LastWindow
  au BufReadPost *.go,*.vim,*.lua JumpToLastLocation
  au BufWritePre * TrimTrailingSpace | TrimTrailingBlankLines
  au BufWritePre *.vim AutoIndent
  au BufWritePost ~/.config/nvim/*.{vim,lua} so $MYVIMRC | e | TransparentBG
aug END

nno <silent> gb        <Cmd>ls<CR>:b<Space>
nno <silent> db        <Cmd>%bd<bar>e#<CR>
nno <silent> <C-n>     <Cmd>let $CD=expand('%:p:h')<CR><Cmd>Term<CR>cd "$CD"<CR>clear<CR>
nno <silent> <F3>      <Cmd>only<CR>
nno <silent> <F8>      <Cmd>Gdiff<CR>
nno <silent> <Leader>w <Cmd>SaveAndClose<CR>
nno          <Leader>c <Cmd>so $VIMRUNTIME/syntax/hitest.vim<CR>
nno <silent> <Space>   @=((foldclosed(line('.')) < 0) ? 'zC' : 'zO')<CR>
cno <expr>   <Up>      wildmenumode() ? "\<Left>"     : "\<Up>"
cno <expr>   <Down>    wildmenumode() ? "\<Right>"    : "\<Down>"
cno <expr>   <Left>    wildmenumode() ? "\<Up>"       : "\<Left>"
cno <expr>   <Right>   wildmenumode() ? "\<BS>\<C-Z>" : "\<Right>"
ino <expr>   <Tab>     luaeval("require'util'.SmartTabComplete()")
ino          '         ''<Left>
ino          (         ()<Left>
ino          [         []<Left>
ino          {         {}<Left>

colo deus
colo deus "beats me why I have to call this twice...

hi LspDiagnosticsVirtualTextError       guifg=Red
hi LspDiagnosticsVirtualTextWarning     guifg=Orange
hi LspDiagnosticsVirtualTextInformation guifg=Pink
hi LspDiagnosticsVirtualTextHint        guifg=Green
hi link LspDiagnosticsSignError       LspDiagnosticsVirtualTextError
hi link LspDiagnosticsSignWarning     LspDiagnosticsVirtualTextWarning
hi link LspDiagnosticsSignInformation LspDiagnosticsVirtualTextInformation
hi link LspDiagnosticsSignHint        LspDiagnosticsVirtualTextHint
hi StatusLineNC gui=NONE                guibg=#222222
hi EndOfBuffer                          guifg=#992277
