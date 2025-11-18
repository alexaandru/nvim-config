(let [signs {:DiagnosticSignError "text=✘ texthl=DiagnosticSignError"
             :DiagnosticSignWarn "text=⚠ texthl=DiagnosticSignWarn"
             :DiagnosticSignInfo "text=i texthl=DiagnosticSignInfo"
             :DiagnosticSignHint "text=h texthl=DiagnosticSignHint"
             :DapBreakpoint "text=🚩"
             :DapStopped "text=⭕"}
      args "define %s %s"]
  (each [sign hl (pairs signs)]
    (vim.cmd.sign (args:format sign hl))))

