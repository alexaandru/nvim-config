(local cfg (require :config.lsp-cfg))
(local {:__diag cfg-diag :__keys lsp-keys} cfg)
(set cfg.__diag nil)
(set cfg.__keys nil)
(local ms 1000)

;;"TRACE", "DEBUG", "INFO", "WARN", "ERROR", "OFF"
(vim.lsp.set_log_level :WARN)

(fn Format []
  (vim.lsp.buf.format {:timeout-ms ms}))

(fn OrgImports []
  (let [params (vim.lsp.util.make_range_params)]
    (set params.context {:only [:source.organizeImports]})
    (let [result (vim.lsp.buf_request_sync 0 :textDocument/codeAction params ms)]
      (each [_ res (pairs (or result {}))]
        (each [_ r (pairs (or res.result {}))]
          (if r.edit
              (vim.lsp.util.apply_workspace_edit r.edit vim.b.offset_encoding)
              (vim.lsp.buf.execute_command r.command)))))))

(fn OrgJSImports []
  (vim.lsp.buf.execute_command {:arguments [(vim.fn.expand "%:p")]
                                :command :_typescript.organizeImports}))

(fn au [group-name commands]
  (let [group (vim.api.nvim_create_augroup group-name {:clear true})
        c #(vim.api.nvim_create_autocmd $1 {:callback $2 : group :buffer 0})]
    (each [ev cmd (pairs commands)] (c ev cmd))
    group))

(fn set-highlight []
  (au :Highlight {:CursorHold vim.lsp.buf.document_highlight
                  :CursorHoldI vim.lsp.buf.document_highlight
                  :CursorMoved vim.lsp.buf.clear_references}))

(local lsp-compl-attach (. (require :lsp_compl) :attach))

;; fnlfmt: skip
(fn on_attach [client bufnr]
  (set vim.b.offset_encoding client.offset_encoding)
  (let [opts {:silent true :buffer true}]
    (each [lhs rhs (pairs lsp-keys)] (vim.keymap.set :n lhs rhs opts)))
  (let [rc client.server_capabilities]
    (if rc.documentHighlightProvider (set-highlight))
    (if rc.codeLensProvider
        (au :CodeLens {[:BufEnter :CursorHold :InsertLeave] vim.lsp.codelens.refresh}))
    (if rc.completionProvider (lsp-compl-attach client bufnr))))

(fn setup []
  (vim.cmd "aug LSP | au!")
  (let [lspc (require :lspconfig)
        cfg-default {: on_attach :flags {:debounce_text_changes 500}}]
    (each [k cfg (pairs cfg)]
      (let [{: setup} (. lspc k)
            cfg (vim.tbl_extend :keep cfg cfg-default)]
        (setup cfg))))
  (vim.cmd "aug END")
  (let [opd vim.lsp.diagnostic.on_publish_diagnostics]
    (tset vim.lsp.handlers :textDocument/publishDiagnostics
          (vim.lsp.with opd cfg-diag)))
  (let [group (vim.api.nvim_create_augroup :Format {:clear true})
        c #(vim.api.nvim_create_autocmd :BufWritePre {: group :callback $1 :pattern $2})]
    (c Format "*")
    (c OrgImports :*.go)
    (c OrgJSImports "*.js,*.jsx")))

{: on_attach : setup}

