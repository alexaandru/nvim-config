(local opts [[:autocomplete false]
             [:autowriteall true]
             [:background :dark]
             [:clipboard :unnamedplus]
             [:completeopt [:fuzzy :menu :noselect :noinsert]]
             [:conceallevel 3]
             [:expandtab true]
             [:fillchars "fold:─"]
             [:findfunc "v:lua.vim.g.findfunc"]
             [:foldexpr "v:lua.vim.treesitter.foldexpr()"]
             [:foldtext ""]
             [:foldmethod :expr]
             [:grepprg "git grep -EIn"]
             [:grepformat "%f:%l:%m"]
             [:ignorecase true]
             [:indentexpr "v:lua.require('nvim-treesitter').indentexpr()"]
             [:laststatus 0]
             [:mouse :a]
             [:mousemodel :extend]
             [:path "**"]
             [:pumblend 10]
             [:signcolumn "yes:2"]
             [:smartcase true]
             [:smartindent true]
             [:splitbelow true]
             [:splitright true]
             [:title true]
             [:titlestring
              (.. "%{v:lua.vim.g.get_zsandbox()}"
                  "🐙 %{v:lua.vim.g.get_git_branch()} %{get(b:,'gitsigns_status','')} "
                  "📚 %<%f%M" "  %{v:lua.vim.g.get_diagnostics_summary()}")]
             [:updatetime 200]
             [:virtualedit [:block :onemore]]
             [:wildcharm (tonumber (vim.keycode :<C-Z>))]
             [:wildignore [:*/.git/* :*/node_modules/*]]
             [:wildignorecase true]
             [:wildmode "noselect:longest,full"]
             [:wildoptions "pum,fuzzy"]
             [:winborder :rounded]
             [:wrap false]])

;; fnlfmt: skip
(local inc-opts [[:complete :kspell]
                 [:diffopt ["algorithm:patience" :indent-heuristic :vertical "linematch:60"]]
                 [:shortmess :c]])

(fn vim.g.get_zsandbox []
  (let [zsandbox vim.env.ZSANDBOX
        {: stylize-text} (require :util)]
    (if (and zsandbox (not= zsandbox ""))
        (.. "🛡️ " (stylize-text zsandbox) " ")
        "")))

(fn vim.g.get_git_branch []
  (let [status-dict vim.b.gitsigns_status_dict]
    (if (and status-dict status-dict.head)
        status-dict.head
        "(no-vcs)")))

(fn vim.g.get_diagnostics_summary []
  (let [bufnr (vim.api.nvim_get_current_buf)
        diagnostics (vim.diagnostic.get bufnr)
        counts {:E 0 :W 0 :I 0 :H 0}
        severity vim.diagnostic.severity]
    (each [_ diag (ipairs diagnostics)]
      (match diag.severity
        severity.ERROR (set counts.E (+ counts.E 1))
        severity.WARN (set counts.W (+ counts.W 1))
        severity.INFO (set counts.I (+ counts.I 1))
        severity.HINT (set counts.H (+ counts.H 1))))
    (let [parts []]
      (if (> counts.E 0) (table.insert parts (.. "❌" counts.E)))
      (if (> counts.W 0) (table.insert parts (.. "⚠️" counts.W)))
      (if (> counts.I 0) (table.insert parts (.. "ℹ️" counts.I)))
      (if (> counts.H 0) (table.insert parts (.. "💡" counts.H)))
      (if (> (length parts) 0)
          (table.concat parts " ")
          ""))))

(fn vim.g.findfunc [cmdarg _cmdcomplete]
  (let [cmd "fd -t f --hidden --color=never --max-depth 10"
        fd-output (vim.fn.systemlist cmd)]
    (if (= (length cmdarg) 0)
        fd-output
        (vim.fn.matchfuzzy fd-output cmdarg {:matchseq 1 :key "tail"}))))

(let [set-opt #(tset vim.opt $1 $2)
      inc-opt #(: (. vim.opt $1) :append $2)]
  (each [_ [opt val] (ipairs opts)] (set-opt opt val))
  (each [_ [opt val] (ipairs inc-opts)] (inc-opt opt val)))

(vim.cmd.colo :monk)
