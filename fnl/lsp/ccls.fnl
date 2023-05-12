(fn switch-source-header [client bufnr]
  (let [method-name :textDocument/switchSourceHeader
        params (vim.lsp.util.make_text_document_params bufnr)]
    (client:request method-name params
                    (fn [err result]
                      (when err (error (tostring err)))
                      (when (not result)
                        (vim.notify "corresponding file cannot be determined")
                        (lua "return "))
                      (vim.cmd.edit (vim.uri_to_fname result)))
                    bufnr)))

{:cmd [:ccls]
 :filetypes [:c :cpp :objc :objcpp :cuda]
 :offset_encoding :utf-32
 :on_attach (fn [client bufnr]
              (vim.api.nvim_buf_create_user_command bufnr
                       :LspCclsSwitchSourceHeader
                       #(switch-source-header client bufnr)
                       {:desc "Switch between source/header"}))
 :root_markers [:compile_commands.json :.ccls :.git]
 :workspace_required true}
