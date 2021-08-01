{:autowriteall true
 :clipboard :unnamedplus
 :complete [:defaults :kspell]
 :completeopt [:menuone :noselect :noinsert]
 :conceallevel 3
 :diffopt [:defaults "algorithm:patience" :indent-heuristic :vertical]
 :expandtab true
 :foldmethod :expr
 :foldexpr "nvim_treesitter#foldexpr()"
 :grepprg "git grep -n"
 :hidden true
 :icon true
 :iconstring :nvim
 :ignorecase true
 :inccommand :nosplit
 :laststatus 0
 :lazyredraw true
 :mouse :a
 :mousemodel :extend
 :omnifunc "v:lua.vim.lsp.omnifunc"
 :path "**"
 :shell :bash
 :shortmess :+c
 :showcmd false
 :showmode false
 :signcolumn "yes:2"
 :smartcase true
 :smartindent true
 :splitbelow true
 :splitright true
 :startofline false
 :termguicolors true
 :title true
 :titlestring "🐙 %{get(w:,'git_status','~git')} 📚 %<%f%=%M  📦 %{nvim_treesitter#statusline(150)}"
 :updatetime 2000
 :virtualedit [:block :onemore]
 ;;<C-Z> == 26
 :wildcharm 26
 :wildignore [:*/.git/* :*/node_modules/*]
 :wildignorecase true
 :wrap false}

