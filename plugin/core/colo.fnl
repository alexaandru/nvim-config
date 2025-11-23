(fn patch-colors []
  (let [hl #(vim.api.nvim_set_hl 0 $1 $2)]
    (hl :Normal {:bg :NONE})
    (hl :NormalFloat {:bg :NONE})
    (hl :NormalNC {:bg :NONE})
    (hl :SignColumn {:bg :NONE})
    (hl :EndOfBuffer {:bg :NONE})
    (hl :Folded {:bg :NONE :link :Comment})
    (hl :PmenuMatch {:fg :Red})
    (hl :MySelect {:fg :Red :bg :blue})
    (hl :PmenuSel {:fg :#CC2666 :bold true :bg :#222232})
    (hl :BlinkCmpLabelMatch {:fg :#CC2666 :bold true})
    (hl :Comment {:fg :#444464})
    (hl :DiagnosticVirtualTextError {:link :DiagnosticError :bg :NONE})
    (hl :DiagnosticVirtualTextWarn {:link :DiagnosticWarn :bg :NONE})
    (hl :DiagnosticVirtualTextInfo {:link :DiagnosticInfo :bg :NONE})
    (hl :DiagnosticVirtualTextHint {:link :DiagnosticHint :bg :NONE})
    (hl :Special {:bg :#89ffb4 :fg :#000000 :bold true})
    (hl "@string.special" {:link :Special})))

;; fnlfmt: skip
(let [au vim.api.nvim_create_autocmd]
  (au :ColorScheme {:pattern "*" :callback patch-colors
                    :desc "Make background transparent after colorscheme change"}))

(vim.cmd.colorscheme :rose-pine)
