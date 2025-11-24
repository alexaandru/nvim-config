(local bg (if vim.g.neovide :#191724 :NONE))
(local color-overrides
       {:Normal {: bg}
        :NormalFloat {: bg}
        :NormalNC {: bg}
        :SignColumn {: bg}
        :EndOfBuffer {: bg}
        :Folded {: bg :link :Comment}
        :PmenuMatch {:fg :Red}
        :MySelect {:fg :Red :bg :blue}
        :PmenuSel {:fg :#CC2666 :bold true :bg :#222232}
        ;:MsgArea {:bg :NONE :fg :#CC2666}
        :BlinkCmpLabelMatch {:fg :#CC2666 :bold true}
        :Comment {:fg :#444464}
        :DiagnosticVirtualTextError {:link :DiagnosticError : bg}
        :DiagnosticVirtualTextWarn {:link :DiagnosticWarn : bg}
        :DiagnosticVirtualTextInfo {:link :DiagnosticInfo : bg}
        :DiagnosticVirtualTextHint {:link :DiagnosticHint : bg}
        ;:PackName {:bg :#89ffb4 :fg :#000000 :bold true}
        :PackName {:bg :#990000 :fg :#ffccff :bold false}
        "@string.special.pack_name" {:link :PackName}})

(let [au vim.api.nvim_create_autocmd
      hl #(vim.api.nvim_set_hl 0 $1 $2)
      colo vim.cmd.colorscheme]
  (au :ColorScheme {:callback #(each [group opts (pairs color-overrides)]
                                 (hl group opts))
                    :desc "Color scheme overrides"})
  ;(colo :rose-pine)
  ;(colo :volcano)
  (colo :monk))
