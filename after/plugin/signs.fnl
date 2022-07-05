(local cmd "sign define %s %s")
(local signs {:DiagnosticSignError "text=🅴 texthl=DiagnosticSignError"
              :DiagnosticSignWarn "text=🆆 texthl=DiagnosticSignWarn"
              :DiagnosticSignInfo "text=🅸 texthl=DiagnosticSignInfo"
              :DiagnosticSignHint "text=🅷 texthl=DiagnosticSignHint"
              :DapBreakpoint "text=🚩"
              :DapStopped "text=⭕"})

(each [sign hl (pairs signs)]
  (vim.cmd (cmd:format sign hl)))

