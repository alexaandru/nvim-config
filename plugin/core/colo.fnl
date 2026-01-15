(local hlx (let [black :#221212
                 pink :#ee16a5
                 white :#cfc9bf
                 red :#cc0000
                 orange :#FF8800
                 green :#008800
                 blue :#2277ff
                 NONE :NONE]
             {:Normal {:fg white :bg NONE}
              :NormalFloat {:bg NONE}
              :NormalNC {:bg NONE}
              :Visual {:fg black :bg orange}
              :VertSplit {:bg NONE}
              :SignColumn {:bg NONE}
              :EndOfBuffer {:bg NONE}
              :Folded {:link :Comment :bg NONE}
              :PmenuMatch {:fg :Red}
              :Pmenu {:fg white :bg NONE}
              :PmenuSel {:fg black :bg orange}
              :Keyword {:bold true}
              :Statement {:link :Keyword}
              :String {:fg orange :italic true}
              :Type {:fg red :italic true}
              "@type.builtin" {:link :Type}
              :Comment {:fg :#555555 :italic true}
              :Constant {:fg red}
              :PreProc {:link :Constant}
              :ErrorMsg {:fg red :bold true}
              :WarningMsg {:fg orange :bold true}
              "@string.special.pack_name" {:bg orange :fg black}
              :DiagnosticVirtualTextError {:link :DiagnosticError :bg NONE}
              :DiagnosticVirtualTextWarn {:link :DiagnosticWarn :bg NONE}
              :DiagnosticVirtualTextInfo {:link :DiagnosticInfo :bg NONE}
              :DiagnosticVirtualTextHint {:link :DiagnosticHint :bg NONE}
              :DiagnosticUnderlineError {:undercurl true :sp red}
              :DiagnosticUnderlineWarn {:undercurl true :sp orange}
              :DiagnosticUnderlineInfo {:undercurl true :sp green}
              :DiagnosticUnderlineHint {:undercurl true :sp blue}
              :DiffAdd {:fg green}
              :DiffChange {:fg orange}
              :DiffDelete {:fg red}
              :DiffText {:fg orange}
              :GitSignsAdd {:fg green}
              :GitSignsChange {:fg orange}
              :GitSignsDelete {:fg red}}))

(fn patch-colors []
  (let [hl #(vim.api.nvim_set_hl 0 $1 $2)]
    (each [name attrs (pairs hlx)] (hl name attrs))
    false))

;; fnlfmt: skip
(let [au vim.api.nvim_create_autocmd]
  (au :ColorScheme {:pattern "*" :callback patch-colors
                    :desc "Make background transparent after colorscheme change"}))
