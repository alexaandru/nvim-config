(local args "define %s %s")
(local signs {:DiagnosticSignError "text=✘ texthl=DiagnosticSignError"
              :DiagnosticSignWarn "text=⚠ texthl=DiagnosticSignWarn"
              :DiagnosticSignInfo "text=i texthl=DiagnosticSignInfo"
              :DiagnosticSignHint "text=h texthl=DiagnosticSignHint"
              :DapBreakpoint "text=🚩"
              :DapStopped "text=⭕"})

(each [sign hl (pairs signs)]
  (vim.cmd.sign (args:format sign hl)))
