(local opts [[:autocomplete false]
             [:autowriteall true]
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
                  "📚 %<%f%M  "
                  "📦 %{v:lua.require('func_stack')()}%{v:lua.vim.g.get_lsp_progress()}")]
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

(fn vim.g.get_git_branch []
  (let [status-dict vim.b.gitsigns_status_dict]
    (if (and status-dict status-dict.head)
        status-dict.head
        "(no-vcs)")))

;; fnlfmt: skip
(fn stylize-text [text]
  (let [normal "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        styled ["𝗮" "𝗯" "𝗰" "𝗱" "𝗲" "𝗳" "𝗴" "𝗵" "𝗶" "𝗷" "𝗸" "𝗹" "𝗺" "𝗻" "𝗼" "𝗽" "𝗾" "𝗿" "𝘀" "𝘁" "𝘂" "𝘃" "𝘄" "𝘅" "𝘆" "𝘇"
                "𝗔" "𝗕" "𝗖" "𝗗" "𝗘" "𝗙" "𝗚" "𝗛" "𝗜" "𝗝" "𝗞" "𝗟" "𝗠" "𝗡" "𝗢" "𝗣" "𝗤" "𝗥" "𝗦" "𝗧" "𝗨" "𝗩" "𝗪" "𝗫" "𝗬" "𝗭"
                "𝟬" "𝟭" "𝟮" "𝟯" "𝟰" "𝟱" "𝟲" "𝟳" "𝟴" "𝟵"]
        result []]
    (for [i 1 (length text)]
      (let [char (text:sub i i)
            idx (normal:find char 1 true)]
        (table.insert result (if idx (. styled idx) char))))
    (table.concat result)))

(fn vim.g.get_zsandbox []
  (let [zsandbox vim.env.ZSANDBOX]
    (if (and zsandbox (not= zsandbox ""))
        (.. "🛡️ " (stylize-text zsandbox) " ")
        "")))

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
