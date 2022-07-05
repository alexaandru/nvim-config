(local cfg (require :config.lsp-cfg))
(local cfg-diag cfg.__diag)
(set cfg.__diag nil)
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

(local {: au} (require :setup))

(fn set-highlight []
  (au {:Highlight [[:CursorHold vim.lsp.buf.document_highlight 0]
                   [:CursorHoldI vim.lsp.buf.document_highlight 0]
                   [:CursorMoved vim.lsp.buf.clear_references 0]]}))

(local {:lsp lsp-keys} (require :config.keys))
(local {: map} (require :setup))

;; fnlfmt: skip
(fn on_attach [client bufnr]
  (set vim.b.offset_encoding client.offset_encoding)
  (map lsp-keys)
  (let [rc client.server_capabilities]
    (if rc.documentHighlightProvider (set-highlight))
    (if rc.codeLensProvider
        (au {:CodeLens [[[:BufEnter :CursorHold :InsertLeave] vim.lsp.codelens.refresh 0]]}))
    (if rc.completionProvider
      ((. (require :lsp_compl) :attach) client bufnr))))

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
  (au {:Format [[:BufWritePre OrgImports :*.go]
                [:BufWritePre OrgJSImports "*.js,*.jsx"]
                [:BufWritePre Format]]}))

{: on_attach : setup}

