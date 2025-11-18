(fn _G.get_git_branch []
  (let [status-dict vim.b.gitsigns_status_dict]
    (if (and status-dict status-dict.head)
        status-dict.head
        "(no-vcs)")))

(fn _G.Fd_findfunc [cmdarg _cmdcomplete]
  (let [cmd "fd -t f --hidden --color=never --max-depth 10"
        fd-output (vim.fn.systemlist cmd)]
    (if (= (length cmdarg) 0)
        fd-output
        (vim.fn.matchfuzzy fd-output cmdarg {:matchseq 1 :key "tail"}))))

;; fnlfmt: skip
(let [set-opt #(tset vim.opt $1 $2)
      append-opt #(: (. vim.opt $1) :append $2)]
  (set-opt :autocomplete false)
  (set-opt :autowriteall true)
  (set-opt :clipboard :unnamedplus)
  (set-opt :completeopt [:fuzzy :menu :noselect :noinsert])
  (set-opt :conceallevel 3)
  (set-opt :expandtab true)
  (set-opt :fillchars "fold:─")
  (set-opt :findfunc "v:lua.Fd_findfunc")
  (set-opt :foldexpr "v:lua.vim.treesitter.foldexpr()")
  (set-opt :foldtext "")
  (set-opt :foldmethod :expr)
  (set-opt :grepprg "git grep -EIn")
  (set-opt :grepformat "%f:%l:%m")
  (set-opt :ignorecase true)
  (set-opt :indentexpr "v:lua.require('nvim-treesitter').indentexpr()")
  (set-opt :laststatus 0)
  (set-opt :mouse :a)
  (set-opt :mousemodel :extend)
  (set-opt :path "**")
  (set-opt :pumblend 10)
  (set-opt :signcolumn "yes:2")
  (set-opt :smartcase true)
  (set-opt :smartindent true)
  (set-opt :splitbelow true)
  (set-opt :splitright true)
  (set-opt :title true)
  (set-opt :titlestring "🐙 %{v:lua.get_git_branch()} %{get(b:,'gitsigns_status','')} 📚 %<%f%M  📦 %{v:lua.require('func_stack')()}%{v:lua.get_lsp_progress()}")
  (set-opt :updatetime 200)
  (set-opt :virtualedit [:block :onemore])
  (set-opt :wildcharm (tonumber (vim.keycode :<C-Z>)))
  (set-opt :wildignore [:*/.git/* :*/node_modules/*])
  (set-opt :wildignorecase true)
  (set-opt :wildmode "noselect:longest,full")
  (set-opt :wildoptions "pum,fuzzy")
  (set-opt :winborder :rounded)
  (set-opt :wrap false)
  (append-opt :complete :kspell)
  (append-opt :diffopt ["algorithm:patience" :indent-heuristic :vertical "linematch:60"])
  (append-opt :shortmess :c))
