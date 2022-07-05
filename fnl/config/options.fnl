{:autowriteall true
 :clipboard :unnamedplus
 :complete [:defaults :kspell]
 :completeopt [:menu :noselect :noinsert]
 :conceallevel 3
 :diffopt [:defaults "algorithm:patience" :indent-heuristic :vertical]
 :expandtab true
 :foldmethod :expr
 :foldexpr "nvim_treesitter#foldexpr()"
 :foldnestmax 4
 :foldminlines 1
 :grepprg "git grep -In"
 :icon true
 :iconstring :nvim
 :ignorecase true
 :laststatus 0
 :lazyredraw true
 :mouse :a
 :mousemodel :extend
 :path "**"
 :pumblend 10
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
 :titlestring "🐙 %{get(w:,'git_status','~git')} 📚 %<%f%=%M  📦 %{nvim_treesitter#statusline()}"
 :updatetime 2000
 :virtualedit [:block :onemore]
 :wildcharm 26 ; <C-Z> == 26
 :wildignore [:*/.git/* :*/node_modules/*]
 :wildignorecase true
 :wildmode "longest:full,full"
 :wildoptions :pum
 :wrap false}

