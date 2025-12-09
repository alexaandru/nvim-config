;; Monk - Minimalist theme with calm blues and red for identifiers

(local bg (if vim.g.neovide
              (let [result (vim.fn.system "grep '^background ' ~/.config/ghostty/themes/monk | awk '{print $3}'")]
                (-> result
                    (: :gsub "\n" "")
                    (: :gsub "\"" "")))
              :NONE))

(local colors {;; Base colors - serene
               :bgs :#131311
               :bg0 :#0e1419
               :bg1 :#1e2429
               :bg2 :#1c2329
               :bg3 :#232a32
               :bg4 :#2a3139
               :fg0 :#d0dae8
               :fg1 :#b8c5d6
               :fg2 :#98a5b6
               :fg3 :#687888
               :fg4 :#484848
               ;; The two main colors
               :blue :#acdef4
               :blue_light :#95b3d4
               :blue_dark :#2aaeff
               :blue_subtle :#8aa8c8
               :red :#ff3366
               ;; Functional colors
               :green :#6b9e6b
               :yellow :#e4b837
               :orange :#c77a4a
               :cyan :#5a9999})

(local highlights {;; Editor UI
                   :Normal {:fg colors.fg0 : bg}
                   :NormalFloat {:fg colors.fg0 : bg}
                   :NormalNC {:fg colors.fg1 : bg}
                   :Cursor {:fg colors.bg0 :bg colors.fg0}
                   :CursorLine {:bg colors.bg2}
                   :CursorColumn {:bg colors.bg2}
                   :ColorColumn {:bg colors.bg2}
                   :LineNr {:fg colors.fg3}
                   :CursorLineNr {:fg colors.blue_light :bold true}
                   :SignColumn {: bg}
                   :Visual {:bg colors.bg4}
                   :VisualNOS {:bg colors.bg4}
                   :Search {:fg colors.bg0 :bg colors.yellow :bold true}
                   :IncSearch {:fg :black :bg colors.cyan}
                   :CurSearch {:fg colors.bg0 :bg colors.blue :bold true}
                   :Pmenu {:fg colors.fg1 :bg colors.bg2}
                   :PmenuSel {:fg :black :bg colors.blue}
                   :PmenuSbar {:bg colors.bg3}
                   :PmenuThumb {:bg colors.fg3}
                   :StatusLine {:fg :black :bg colors.blue}
                   :StatusLineNC {:fg colors.fg2 :bg colors.bg2}
                   :WinBar {:fg colors.blue :bg :NONE}
                   :WinBarNC {:fg colors.fg3 :bg :NONE}
                   :TabLine {:fg colors.fg2 :bg colors.bg2}
                   :TabLineFill {:bg colors.bg1}
                   :TabLineSel {:fg colors.fg0 :bg colors.bg3 :bold true}
                   :Folded {: bg :link :Comment}
                   :FoldColumn {:fg colors.fg3 :bg colors.bg0}
                   :VertSplit {:fg colors.bg4}
                   :WinSeparator {:fg colors.bg4}
                   :Directory {:fg colors.blue :bold true}
                   :Title {:fg colors.blue_light :bold true}
                   :ErrorMsg {:fg colors.red :bold true}
                   :WarningMsg {:fg colors.orange :bold true}
                   :MoreMsg {:fg colors.blue}
                   :ModeMsg {:fg colors.blue_subtle}
                   ;:MsgArea {:bg :NONE :fg :#CC2666}
                   :Question {:fg colors.blue}
                   :MatchParen {:fg colors.orange :bold true :underline true}
                   :NonText {:fg colors.bg4}
                   :SpecialKey {:fg colors.bg4}
                   :Whitespace {:fg colors.bg3}
                   :EndOfBuffer {:fg colors.bg0 : bg}
                   ;; Mine
                   :PackName {:bg colors.yellow :fg :black}
                   "@string.special.pack_name" {:link :PackName}
                   ;; Syntax - THE MONK WAY
                   :Comment {:fg colors.fg4 :italic true}
                   :Constant {:fg colors.blue_dark}
                   :String {:fg colors.yellow :italic true}
                   :Character {:fg colors.blue}
                   :Number {:fg colors.orange}
                   :Boolean {:fg colors.blue_dark}
                   :Float {:fg colors.blue_dark}
                   :Identifier {:fg colors.blue}
                   :Function {:fg colors.blue}
                   :Statement {:fg colors.blue :bold true}
                   :Conditional {:fg colors.blue :bold true}
                   :Repeat {:fg colors.blue :bold true}
                   :Label {:fg colors.blue :bold true}
                   :Operator {:fg colors.blue_light}
                   :Keyword {:fg colors.blue :bold true}
                   :Exception {:fg colors.blue :bold true}
                   :PreProc {:fg colors.blue}
                   :Include {:fg colors.blue :bold true}
                   :Define {:fg colors.blue}
                   :Macro {:fg colors.blue}
                   :PreCondit {:fg colors.blue}
                   :Type {:fg colors.blue_light}
                   :StorageClass {:fg colors.blue :bold true}
                   :Structure {:fg colors.blue_light}
                   :Typedef {:fg colors.blue_light}
                   :Special {:fg colors.red}
                   :SpecialChar {:fg colors.blue_dark}
                   :Tag {:fg colors.blue}
                   :Delimiter {:fg colors.fg2}
                   :SpecialComment {:fg colors.blue_subtle :italic true}
                   :Debug {:fg colors.blue}
                   :Underlined {:underline true}
                   :Ignore {:fg colors.bg4}
                   :Error {:fg colors.red :bold true}
                   :Todo {:fg colors.bg0 :bg colors.yellow :bold true}
                   ;; Treesitter - RED FOR IDENTIFIERS
                   "@variable" {:fg colors.blue}
                   "@variable.builtin" {:fg colors.blue :bold true}
                   "@variable.parameter" {:fg colors.blue}
                   "@variable.member" {:fg colors.blue}
                   "@constant" {:fg colors.blue_dark}
                   "@constant.builtin" {:fg colors.red :bold true}
                   "@constant.macro" {:fg colors.blue}
                   "@string" {:fg colors.yellow :italic true}
                   "@string.escape" {:fg colors.blue_dark}
                   "@string.special" {:fg colors.red}
                   "@character" {:fg colors.blue}
                   "@number" {:link :Number}
                   "@boolean" {:link :Special}
                   "@float" {:fg colors.blue_dark}
                   "@function" {:fg colors.blue}
                   "@function.builtin" {:fg colors.blue :bold true}
                   "@function.macro" {:fg colors.blue}
                   "@function.method" {:fg colors.blue}
                   "@constructor" {:fg colors.blue_light}
                   "@keyword" {:fg colors.blue :bold true}
                   "@keyword.function" {:fg colors.blue :bold true}
                   "@keyword.operator" {:fg colors.blue :bold true}
                   "@keyword.return" {:fg colors.blue :bold true}
                   "@conditional" {:fg colors.blue :bold true}
                   "@repeat" {:fg colors.blue :bold true}
                   "@label" {:fg colors.blue :bold true}
                   "@operator" {:fg colors.blue_light}
                   "@exception" {:fg colors.blue :bold true}
                   "@type" {:fg colors.red}
                   "@type.builtin" {:fg colors.red}
                   "@type.qualifier" {:fg colors.red :bold true}
                   "@property" {:fg colors.blue}
                   "@attribute" {:fg colors.blue}
                   "@tag" {:fg colors.blue}
                   "@tag.attribute" {:fg colors.blue}
                   "@tag.delimiter" {:fg colors.fg3}
                   "@comment" {:link :Comment}
                   "@punctuation.delimiter" {:fg colors.fg2}
                   "@punctuation.bracket" {:fg colors.fg2}
                   "@punctuation.special" {:fg colors.blue}
                   ;; TressitterContext
                   :TreesitterContext {:bg colors.bg1}
                   ;; LSP
                   :LspReferenceText {:bg colors.bg3}
                   :LspReferenceRead {:bg colors.bg3}
                   :LspReferenceWrite {:bg colors.bg3}
                   :DiagnosticError {:fg colors.red}
                   :DiagnosticWarn {:fg colors.yellow}
                   :DiagnosticInfo {:fg colors.blue}
                   :DiagnosticHint {:fg colors.cyan}
                   :DiagnosticVirtualTextError {:link :DiagnosticError : bg}
                   :DiagnosticVirtualTextWarn {:link :DiagnosticWarn : bg}
                   :DiagnosticVirtualTextInfo {:link :DiagnosticInfo : bg}
                   :DiagnosticVirtualTextHint {:link :DiagnosticHint : bg}
                   :DiagnosticUnderlineError {:undercurl true :sp colors.red}
                   :DiagnosticUnderlineWarn {:undercurl true :sp colors.orange}
                   :DiagnosticUnderlineInfo {:undercurl true :sp colors.blue}
                   :DiagnosticUnderlineHint {:undercurl true :sp colors.cyan}
                   ;; LSP Semantic Tokens
                   "@lsp.type.namespace" {:fg colors.cyan}
                   "@lsp.type.interface" {:fg colors.blue_light :italic true}
                   "@lsp.type.enum" {:fg colors.blue_light}
                   "@lsp.type.enumMember" {:fg colors.blue_dark}
                   "@lsp.type.typeParameter" {:fg colors.blue_light
                                              :italic true}
                   "@lsp.type.decorator" {:fg colors.blue}
                   "@lsp.type.macro" {:fg colors.blue}
                   "@lsp.type.comment.documentation" {:fg colors.fg3
                                                      :italic true
                                                      :bold true}
                   ;; Format strings - Printf format specifiers!
                   "@lsp.typemod.string.format" {:fg colors.cyan}
                   ;; Modifiers
                   "@lsp.mod.readonly" {:fg colors.red}
                   "@lsp.mod.deprecated" {:fg colors.fg3 :strikethrough true}
                   "@lsp.mod.defaultLibrary" {:fg colors.red :bold true}
                   ;; Git
                   :DiffAdd {:fg colors.green :bg colors.bg2}
                   :DiffChange {:fg colors.yellow :bg colors.bg2}
                   :DiffDelete {:fg colors.red :bg colors.bg2}
                   :DiffText {:fg colors.yellow :bg colors.bg3}
                   :GitSignsAdd {:fg colors.green}
                   :GitSignsChange {:fg colors.yellow}
                   :GitSignsDelete {:fg colors.red}})

(fn []
  (vim.cmd "hi clear")
  (if (vim.fn.exists :syntax_on)
      (vim.cmd "syntax reset"))
  (set vim.o.background :dark)
  (set vim.g.colors_name :monk)
  (each [group opts (pairs highlights)]
    (vim.api.nvim_set_hl 0 group opts)))
