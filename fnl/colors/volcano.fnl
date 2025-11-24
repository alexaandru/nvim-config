(local colors {;; Base colors - deep warm darkness
               :bg0 :#0d0a0f
               :bg1 :#1a0f18
               :bg2 :#251522
               :bg3 :#331d2e
               :bg4 :#432839
               :fg0 :#ffe9f5
               :fg1 :#ffd4e8
               :fg2 :#ffb8d6
               :fg3 :#cc88aa
               ;; Explosive accent colors - VIVID!
               :pink_hot :#ff2b8b
               :pink :#ff66b3
               :pink_soft :#ffaad5
               :orange_fire :#ff5f00
               :orange :#ff8829
               :orange_bright :#ffb366
               :red_hot :#ff1744
               :red :#ff4466
               :red_soft :#ff6b88
               :yellow_gold :#ffcc00
               :yellow :#ffc34f
               :yellow_soft :#fff59d
               :coral :#ff7b5a
               :peach :#ffab91
               :magenta :#ff44cc
               :purple :#dd66ff
               :purple_deep :#bb44ff
               :cyan :#44eeff
               :teal :#00ffcc})

(local highlights {;; Editor UI
                   :Normal {:fg colors.fg0 :bg colors.bg0}
                   :NormalFloat {:fg colors.fg0 :bg colors.bg1}
                   :NormalNC {:fg colors.fg1 :bg colors.bg0}
                   :Cursor {:fg colors.bg0 :bg colors.fg0}
                   :CursorLine {:bg colors.bg2}
                   :CursorColumn {:bg colors.bg2}
                   :ColorColumn {:bg colors.bg2}
                   :LineNr {:fg colors.fg3}
                   :CursorLineNr {:fg colors.yellow_gold :bold true}
                   :SignColumn {:bg colors.bg0}
                   :Visual {:bg colors.bg4}
                   :VisualNOS {:bg colors.bg4}
                   :Search {:fg colors.bg0 :bg colors.yellow :bold true}
                   :IncSearch {:fg colors.bg0
                               :bg colors.orange_fire
                               :bold true}
                   :CurSearch {:fg colors.bg0 :bg colors.pink_hot :bold true}
                   :Pmenu {:fg colors.fg1 :bg colors.bg2}
                   :PmenuSel {:fg colors.fg0 :bg colors.bg4 :bold true}
                   :PmenuSbar {:bg colors.bg3}
                   :PmenuThumb {:bg colors.fg3}
                   :StatusLine {:fg colors.fg0 :bg colors.bg3}
                   :StatusLineNC {:fg colors.fg2 :bg colors.bg2}
                   :WinBar {:fg colors.fg1 :bg :NONE}
                   :WinBarNC {:fg colors.fg3 :bg :NONE}
                   :TabLine {:fg colors.fg2 :bg colors.bg2}
                   :TabLineFill {:bg colors.bg1}
                   :TabLineSel {:fg colors.fg0 :bg colors.bg3 :bold true}
                   :Folded {:fg colors.fg3 :bg colors.bg2}
                   :FoldColumn {:fg colors.fg3 :bg colors.bg0}
                   :VertSplit {:fg colors.bg4}
                   :WinSeparator {:fg colors.bg4}
                   :Directory {:fg colors.pink :bold true}
                   :Title {:fg colors.yellow_gold :bold true}
                   :ErrorMsg {:fg colors.red_hot :bold true}
                   :WarningMsg {:fg colors.orange :bold true}
                   :MoreMsg {:fg colors.peach}
                   :ModeMsg {:fg colors.pink_soft}
                   :Question {:fg colors.yellow}
                   :MatchParen {:fg colors.pink_hot :bold true :underline true}
                   :NonText {:fg colors.bg4}
                   :SpecialKey {:fg colors.bg4}
                   :Whitespace {:fg colors.bg3}
                   :EndOfBuffer {:fg colors.bg0 :bg colors.bg0}
                   ;; Syntax - EXPLOSIVE
                   :Comment {:fg colors.fg3 :italic true}
                   :Constant {:fg colors.orange_bright}
                   :String {:fg colors.peach}
                   :Character {:fg colors.coral}
                   :Number {:fg colors.orange_fire :bold true}
                   :Boolean {:fg colors.yellow_gold :bold true}
                   :Float {:fg colors.orange :bold true}
                   :Identifier {:fg colors.pink_soft}
                   :Function {:fg colors.yellow :bold true}
                   :Statement {:fg colors.pink_hot}
                   :Conditional {:fg colors.magenta :bold true}
                   :Repeat {:fg colors.magenta :bold true}
                   :Label {:fg colors.pink}
                   :Operator {:fg colors.red_soft}
                   :Keyword {:fg colors.red_hot :bold true}
                   :Exception {:fg colors.red_hot :bold true}
                   :PreProc {:fg colors.yellow_soft}
                   :Include {:fg colors.pink_hot :bold true}
                   :Define {:fg colors.orange}
                   :Macro {:fg colors.yellow}
                   :PreCondit {:fg colors.orange_bright}
                   :Type {:fg colors.yellow_gold :bold true}
                   :StorageClass {:fg colors.purple}
                   :Structure {:fg colors.yellow}
                   :Typedef {:fg colors.yellow_soft}
                   :Special {:fg colors.pink}
                   :SpecialChar {:fg colors.pink_hot}
                   :Tag {:fg colors.coral}
                   :Delimiter {:fg colors.fg2}
                   :SpecialComment {:fg colors.pink_soft :italic true}
                   :Debug {:fg colors.red_hot}
                   :Underlined {:underline true}
                   :Ignore {:fg colors.bg4}
                   :Error {:fg colors.red_hot :bold true}
                   :Todo {:fg colors.bg0 :bg colors.yellow_gold :bold true}
                   ;; Treesitter - VIVID
                   "@variable" {:fg colors.pink_soft}
                   "@variable.builtin" {:fg colors.red_hot :bold true}
                   "@variable.parameter" {:fg colors.coral}
                   "@variable.member" {:fg colors.peach}
                   "@constant" {:fg colors.orange_bright :bold true}
                   "@constant.builtin" {:fg colors.orange_fire :bold true}
                   "@constant.macro" {:fg colors.yellow}
                   "@string" {:fg colors.peach}
                   "@string.escape" {:fg colors.pink_hot :bold true}
                   "@string.special" {:fg colors.pink}
                   "@character" {:fg colors.coral}
                   "@number" {:fg colors.orange_fire :bold true}
                   "@boolean" {:fg colors.yellow_gold :bold true}
                   "@float" {:fg colors.orange :bold true}
                   "@function" {:fg colors.yellow :bold true}
                   "@function.builtin" {:fg colors.yellow_gold :bold true}
                   "@function.macro" {:fg colors.yellow_soft}
                   "@function.method" {:fg colors.yellow :bold true}
                   "@constructor" {:fg colors.orange_bright :bold true}
                   "@keyword" {:fg colors.red_hot :bold true}
                   "@keyword.function" {:fg colors.pink_hot :bold true}
                   "@keyword.operator" {:fg colors.magenta :bold true}
                   "@keyword.return" {:fg colors.pink_hot :bold true}
                   "@conditional" {:fg colors.magenta :bold true}
                   "@repeat" {:fg colors.magenta :bold true}
                   "@label" {:fg colors.pink}
                   "@operator" {:fg colors.red_soft}
                   "@exception" {:fg colors.red_hot :bold true}
                   "@type" {:fg colors.yellow_gold :bold true}
                   "@type.builtin" {:fg colors.yellow :bold true}
                   "@type.qualifier" {:fg colors.purple}
                   "@property" {:fg colors.coral}
                   "@attribute" {:fg colors.orange_bright}
                   "@tag" {:fg colors.pink_hot}
                   "@tag.attribute" {:fg colors.orange}
                   "@tag.delimiter" {:fg colors.fg3}
                   "@comment" {:link :Comment}
                   "@punctuation.delimiter" {:fg colors.pink_soft}
                   "@punctuation.bracket" {:fg colors.pink_soft}
                   "@punctuation.special" {:fg colors.pink_hot}
                   ;; LSP
                   :LspReferenceText {:bg colors.bg3}
                   :LspReferenceRead {:bg colors.bg3}
                   :LspReferenceWrite {:bg colors.bg3}
                   :DiagnosticError {:fg colors.red_hot}
                   :DiagnosticWarn {:fg colors.orange}
                   :DiagnosticInfo {:fg colors.yellow_soft}
                   :DiagnosticHint {:fg colors.peach}
                   :DiagnosticVirtualTextError {:fg colors.red_hot
                                                :bg colors.bg0}
                   :DiagnosticVirtualTextWarn {:fg colors.orange
                                               :bg colors.bg0}
                   :DiagnosticVirtualTextInfo {:fg colors.yellow_soft
                                               :bg colors.bg0}
                   :DiagnosticVirtualTextHint {:fg colors.peach :bg colors.bg0}
                   :DiagnosticUnderlineError {:undercurl true
                                              :sp colors.red_hot}
                   :DiagnosticUnderlineWarn {:undercurl true :sp colors.orange}
                   :DiagnosticUnderlineInfo {:undercurl true :sp colors.yellow}
                   :DiagnosticUnderlineHint {:undercurl true :sp colors.coral}
                   ;; Git
                   :DiffAdd {:fg colors.teal :bg colors.bg2}
                   :DiffChange {:fg colors.orange :bg colors.bg2}
                   :DiffDelete {:fg colors.red_hot :bg colors.bg2}
                   :DiffText {:fg colors.yellow_gold :bg colors.bg3}
                   :GitSignsAdd {:fg colors.teal}
                   :GitSignsChange {:fg colors.orange}
                   :GitSignsDelete {:fg colors.red_hot}})

(fn []
  (vim.cmd "hi clear")
  (if (vim.fn.exists :syntax_on)
      (vim.cmd "syntax reset"))
  (set vim.o.background :dark)
  (set vim.g.colors_name :volcano)
  (each [group opts (pairs highlights)]
    (vim.api.nvim_set_hl 0 group opts)))
