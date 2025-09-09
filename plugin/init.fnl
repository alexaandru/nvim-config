(vim.loader.enable)

;; fnlfmt: skip
(local packs [:OXY2DEV/markview.nvim
              :Saghen/blink.cmp
              :alexaandru/fennel-nvim
              :alexaandru/froggy
              :alexaandru/site-util
              :dstein64/vim-startuptime
              :folke/snacks.nvim
              :folke/which-key.nvim
              :ibhagwan/fzf-lua
              :lewis6991/gitsigns.nvim
              :luukvbaal/statuscol.nvim
              :nvim-lua/plenary.nvim
              :nvim-tree/nvim-web-devicons
               ;; TODO: implement pack update hooks
              {:src :nvim-treesitter/nvim-treesitter :version :main :data {:after [":TSUpdate"]}}
              :nvim-treesitter/nvim-treesitter-context
              {:src :nvim-treesitter/nvim-treesitter-textobjects :version :main}
              :olimorris/codecompanion.nvim
              :ravitemer/mcphub.nvim
              :terrastruct/d2-vim
              :windwp/nvim-ts-autotag])

;; fnlfmt: skip
(local {: !providers : !builtin : packadd
        : au : lēt : opt : com : map} (require :setup))

(packadd packs)

(!providers [:python3 :node :ruby :perl])

;; fnlfmt: skip
(!builtin [:2html_plugin :man :matchit :netrwPlugin
           :tutor_mode_plugin :tarPlugin :zipPlugin])

(lēt {:g {:EMPTY (vim.empty_dict)
           ;; FixCursorHold settings
           :cursorhold_updatetime 500
           ;:froggy_default_bg "#230929"
           :netrw {:banner 0 :winsize -25}}})

;; fnlfmt: skip
(local diffopt [:defaults "algorithm:patience" :indent-heuristic :vertical "linematch:60"])

(opt {:autowriteall true
      :clipboard :unnamedplus
      :cmdheight 1
      :complete [:defaults :kspell]
      :completeopt [:menu :noselect :noinsert]
      :conceallevel 3
      : diffopt
      :expandtab true
      :fillchars "fold:─"
      :foldexpr "v:lua.vim.treesitter.foldexpr()"
      ;:foldtext "v:lua.vim.treesitter.foldtext()"
      :foldtext ""
      ;:foldlevel 99
      :foldmethod :expr
      ;:foldminlines 1
      ;:foldnestmax 4
      :grepprg "git grep -EIn"
      :grepformat "%f:%l:%m"
      :icon true
      :iconstring :nvim
      :ignorecase true
      :laststatus 0
      :lazyredraw true
      :modelineexpr true
      :mouse :a
      :mousemodel :extend
      :path ".,**"
      :pumblend 10
      :shell :zsh
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
      :titlestring "🐙 %{get(get(b:,'gitsigns_status_dict',g:EMPTY), 'head', '(vcs)')} %{get(b:,'gitsigns_status','')} 📚 %<%f%M  📦 %{v:lua.ts_func_stack()}"
      :updatetime 2000
      :virtualedit [:block :onemore]
      :wildcharm (tonumber (vim.keycode :<C-Z>))
      :wildignore [:*/.git/* :*/node_modules/*]
      :wildignorecase true
      :wildmode "longest:full,full"
      :wildoptions :pum
      :wrap false})

(local {: LoadLocalCfg : ReColor : LspHintsToggle : PackChanged}
       (require :config.autocmd))

;; Format is: [<item>], where each <item> is itself a list of:
;; <event>,                // event type (string or list)
;; <command_or_callback>,  // command (string) or callback (function)
;; [, <buffer_or_pattern>  // buffer (number) or pattern (string), default is "*"
;;  [, <desc>]]            // callback description
(au {:Setup [[[:VimEnter :DirChanged] LoadLocalCfg]
             [:VimEnter :CdProjRoot]
             [:PackChanged PackChanged]
             [:InsertEnter #(LspHintsToggle false)]
             [:InsertLeave #(LspHintsToggle (not= false vim.b.hints))]
             [:TextYankPost #(vim.highlight.on_yank {:timeout 450})]
             [:QuickFixCmdPost :cw "[^l]*"]
             [:QuickFixCmdPost :lw :l*]
             [:TermOpen :star]
             [:TermClose :q]
             [:FileType :AutoWinHeight :qf]
             [:FileType "setl cul" :qf]
             [:FileType "setl spell spl=en_us" "gitcommit,asciidoc,markdown"]
             [:FileType "setl ts=2 sw=2 sts=2 fdls=0" "lua,vim,zsh"]
             [:FileType "setl ts=4 sw=4 noet cole=1" :go]
             [:FileType #(pcall vim.treesitter.start)]
             [:BufEnter :LastWindow]
             [:BufEnter "setl ft=nginx" :nginx/*]
             [:BufEnter "setl ft=risor" :*.risor]
             [:BufEnter :startinsert :dap-repl]
             [:BufReadPost :JumpToLastLocation]
             [:BufWritePost ReColor :*froggy/*]
             [:BufWritePre "TrimTrailingSpace | TrimTrailingBlankLines" :*.txt]]})

(local {: FzFiles : LspCapabilities : LastWindow : LspHintsToggle}
       (require :config.commands))

;; Format is: {CommandName CommandSpec, ...}
;; where CommandSpec is either String, Table or Lua function.
;;
;; If it is Table, then the command itself must be passed in .cmd, the
;; rest of CommandSpec is treated as arguments to command:
;;   :cmd - command (as string) or function;
;;   :bar - autofilled for strings based on absence of pipe symbol and
;;          always ON for functions, unless already set;
;;   :range - if <line1> is present in command string (or command
;;            is a function), then range is set automaticall to %;
;;   :nargs - if <args> is present in command string, then is set to 1,
;;            for functions it is always set to "*".
(com {:Grep {:cmd "sil grep <args>" :bar false}
      :PackUpdate "lua vim.pack.update()"
      :FzFiles {:cmd FzFiles :complete :file}
      :Term {:cmd "12split | term <args>" :nargs "*"}
      :SetProjRoot "let w:proj_root = fnamemodify(finddir('.git/..', expand('%:p:h').';'), ':p')"
      :CdProjRoot "SetProjRoot | cd `=w:proj_root`"
      :JumpToLastLocation "let b:pos = line('''\"') | if b:pos && b:pos <= line('$') | exe b:pos | endif"
      :SaveAndClose "up | bdel"
      : LastWindow
      :Scratchify "setl nobl bt=nofile bh=delete noswf"
      :Scratch "<mods> new +Scratchify"
      :AutoWinHeight "sil exe max([min([line('$')+1, 16]), 1]).'wincmd _'"
      : LspCapabilities
      : LspHintsToggle
      :JQ {:cmd "<line1>,<line2>!jq -S ." :range true}})

(map (let [S {:silent true}
           toggle-fold "@=((foldclosed(line('.')) < 0) ? 'zc' : 'zO')<CR>"
           syn-stack "<Cmd>echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, \"name\")')<CR>"]
       {:n [[:gb "<Cmd>ls<CR>:b<Space>" S]
            [:db "<Cmd>%bd<bar>e#<CR>" S]
            [:<C-P> :<Cmd>FzFiles<CR> S]
            [:<C-S-P> :<Cmd>FzfLua<CR> S]
            [:<C-Q> "<Cmd>FzfLua live_grep<CR>" S]
            [:<F5> :<Cmd>Inspect<CR>]
            [:<F3> vim.cmd.only S]
            [:<F8> :<Cmd>Gdiff<CR> S]
            [:<Leader>w :<Cmd>SaveAndClose<CR> S]
            [:<Leader>s #(pcall vim.treesitter.start 0)]
            [:<Space> toggle-fold S]
            [:Q :<Nop> S]
            [:<Esc> :<Cmd>noh<CR>]
            ["," ":find "]
            [:<F10> syn-stack S]]
        :i [["'" "''<Left>"]
            ["(" "()<Left>"]
            ["[" "[]<Left>"]
            ["{" "{}<Left>"]]}))

;((. (require :fzf-lua) :register_ui_select))

(vim.cmd.colorscheme :challenge)
