(vim.loader.enable)

(local packs [:OXY2DEV/markview.nvim
              :alexaandru/site-util
              ;:dstein64/vim-startuptime
              :folke/sidekick.nvim
              ;:folke/tokyonight.nvim
              :lewis6991/gitsigns.nvim
              :nvim-tree/nvim-web-devicons
              {:src :nvim-treesitter/nvim-treesitter
               :version :main
               :data {:after :TSUpdate}}
              :nvim-treesitter/nvim-treesitter-context
              {:src :nvim-treesitter/nvim-treesitter-textobjects
               :version :main}
              ;:olimorris/codecompanion.nvim
              ;:ravitemer/mcphub.nvim
              :rose-pine/neovim
              :terrastruct/d2-vim
              :windwp/nvim-ts-autotag])

;; fnlfmt: skip
(local {: !providers : !builtin : packadd
        : au : lēt : opt : com : map} (require :setup))

(local {: PackChanged} (require :config.autocmd))

;; NOTE: Needs to be hooked before vim.pack.add() runs.
(au {:PackSetup [[:PackChanged PackChanged]]})

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

; A one-liner which sets autocomplete to false on all non-normal buffers:
;
; vim.bo.autocomplete = vim.bo.buftype == ''

(opt {:autocomplete false
      :autowriteall true
      :clipboard :unnamedplus
      :cmdheight 1
      :complete [:defaults :kspell]
      :completeopt [:fuzzy :menu :noselect :noinsert]
      :conceallevel 3
      : diffopt
      :expandtab true
      :fillchars "fold:─"
      :foldexpr "v:lua.vim.treesitter.foldexpr()"
      :foldtext ""
      :foldmethod :expr
      ;:foldminlines 1
      ;:foldnestmax 4
      :grepprg "git grep -EIn"
      :grepformat "%f:%l:%m"
      :icon true
      :iconstring :nvim
      :ignorecase true
      :indentexpr "v:lua.require(“nvim-treesitter”).indentexpr()"
      :laststatus 0
      :lazyredraw true
      :modelineexpr true
      :mouse :a
      :mousemodel :extend
      :path "**"
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
      :titlestring "🐙 %{get(get(b:,'gitsigns_status_dict',g:EMPTY), 'head', '(vcs)')} %{get(b:,'gitsigns_status','')} 📚 %<%f%M  📦 %{v:lua.ts_func_stack()}%{v:lua.get_lsp_progress()}"
      :updatetime 200
      :virtualedit [:block :onemore]
      :wildcharm (tonumber (vim.keycode :<C-Z>))
      :wildignore [:*/.git/* :*/node_modules/*]
      :wildignorecase true
      :wildmode "noselect:longest,full"
      :wildoptions "pum,fuzzy"
      :winborder :rounded
      :wrap false})

(local {: LoadLocalCfg : ReColor : LspHintsToggle} (require :config.autocmd))

;; Format is: [<item>], where each <item> is itself a list of:
;; <event>,                // event type (string or list)
;; <command_or_callback>,  // command (string) or callback (function)
;; [, <buffer_or_pattern>  // buffer (number) or pattern (string), default is "*"
;;  [, <desc>]]            // callback description
(au {:Setup [[[:VimEnter :DirChanged] LoadLocalCfg]
             [:VimEnter :CdProjRoot]
             [:VimResized "wincmd ="]
             [:InsertEnter #(LspHintsToggle false)]
             [:InsertLeave #(LspHintsToggle (not= false vim.b.hints))]
             [:TextYankPost #(vim.highlight.on_yank {:timeout 450})]
             [:QuickFixCmdPost :cw "[^l]*"]
             [:QuickFixCmdPost :lw :l*]
             [:TermOpen :star]
             [:TermClose :q]
             [:FileType "wincmd L" :help]
             [:FileType :AutoWinHeight :qf]
             [:FileType "setl cul" :qf]
             [:FileType "setl spell spl=en_us" "gitcommit,asciidoc,markdown"]
             [:FileType "setl ts=2 sw=2 sts=2 fdls=0" "lua,vim,zsh"]
             [:FileType "setl ts=4 sw=4 noet cole=1" :go]
             ;; https://www.reddit.com/r/neovim/comments/1oxgrnx/enabling_treesitter_highlighting_if_its_installed/
             [:FileType #(let [_ (pcall vim.treesitter.start)] false)]
             [:BufEnter :LastWindow]
             [:BufEnter "setl ft=nginx" :nginx/*]
             [:BufEnter "setl ft=risor" :*.risor]
             [:BufEnter :startinsert :dap-repl]
             [:BufReadPost :JumpToLastLocation]
             [:BufWritePost ReColor :*froggy/*]
             [:BufWritePre "TrimTrailingSpace | TrimTrailingBlankLines" :*.txt]]})

;; fnlfmt: skip
(local {: LspCapabilities : LastWindow : LspHintsToggle : SetProjRoot : BuiltinPacks}
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
      :PackUp #(vim.pack.update)
      :Term {:cmd "12split | term <args>" :nargs "*"}
      : SetProjRoot
      :CdProjRoot "SetProjRoot | cd `=w:proj_root`"
      :JumpToLastLocation "let b:pos = line('''\"') | if b:pos && b:pos <= line('$') | exe b:pos | endif"
      :SaveAndClose "up | bdel"
      : LastWindow
      :Scratchify "setl nobl bt=nofile bh=delete noswf"
      :Scratch "<mods> new +Scratchify"
      :AutoWinHeight "sil exe max([min([line('$')+1, 16]), 1]).'wincmd _'"
      : LspCapabilities
      : LspHintsToggle
      : BuiltinPacks
      :JQ {:cmd "<line1>,<line2>!jq -S ." :range true}})

(map (let [S {:silent true}]
       {:n [[:gb "<Cmd>ls<CR>:b<Space>" S]
            [:db "<Cmd>%bd<bar>e#<CR>" S]
            [:<F2> :Grep S]
            [:<F3> vim.cmd.only S]
            [:<F5> :<Cmd>Inspect<CR>]
            [:<F8> :<Cmd>Gdiff<CR> S]
            [:<Leader>w :<Cmd>SaveAndClose<CR> S]
            [:<Space> "@=((foldclosed(line('.')) < 0) ? 'zc' : 'zO')<CR>" S]
            [:Q :<Nop> S]
            [:<Esc> :<Cmd>noh<CR>]
            ["," ":find "]]
        :i [["'" "''<Left>"]
            ["(" "()<Left>"]
            ["[" "[]<Left>"]
            ["{" "{}<Left>"]]}))

(vim.cmd.colorscheme :rose-pine)
