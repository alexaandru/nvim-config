(let [signs {:DiagnosticSignError "text=✘ texthl=DiagnosticSignError"
             :DiagnosticSignWarn "text=⚠ texthl=DiagnosticSignWarn"
             :DiagnosticSignInfo "text=⚠ texthl=DiagnosticSignInfo"
             :DiagnosticSignHint "text=⚠ texthl=DiagnosticSignHint"
             :DapBreakpoint "text=🚩"
             :DapStopped "text=⭕"}
      args "define %s %s"]
  (each [sign hl (pairs signs)]
    (vim.cmd.sign (args:format sign hl))))
