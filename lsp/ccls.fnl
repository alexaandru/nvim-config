(fn switch-source-header [client bufnr]
  (let [method-name :textDocument/switchSourceHeader
        params (vim.lsp.util.make_text_document_params bufnr)]
    (client:request method-name params
                    (fn [err result]
                      (if err (error (tostring err)) result
                          (vim.cmd.edit (vim.uri_to_fname result))
                          (vim.notify "corresponding file cannot be determined")))
                    bufnr)))

(let [com vim.api.nvim_buf_create_user_command]
  {:cmd [:ccls]
   :filetypes [:c :cpp :objc :objcpp :cuda]
   :offset_encoding :utf-32
   :on_attach #(com $2 :LspCclsSwitchSourceHeader #(switch-source-header $ $2)
                    {:desc "Switch between source/header"})
   :root_markers [:compile_commands.json :.ccls :.git]
   :workspace_required true})
