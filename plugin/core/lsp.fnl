
;; fnlfmt: skip
(local diagnostic-config
       (let [s vim.diagnostic.severity
               signs {:text {s.ERROR "✘" s.WARN "⚠" s.INFO "⚠" s.HINT "⚠"}}]
         {:underline true
          :virtual_text {:spacing 0 :prefix "‼"}
          : signs
          :status signs
          :update_in_insert true
          :severity_sort true
          :float {:border :rounded :source true :suffix " " :severity_sort true :header ""}}))

(vim.lsp.inline_completion.enable true)
(vim.lsp.document_color.enable)
(vim.lsp.log.set_level vim.log.levels.ERROR)
(vim.diagnostic.config diagnostic-config)
(vim.defer_fn (. (require :mini.icons) :tweak_lsp_kind) 10)

(fn apply-code-actions [actions]
  (let [bufnr (vim.api.nvim_get_current_buf)
        clients (vim.lsp.get_clients {: bufnr})]
    (each [_ client (ipairs clients)]
      (if (client:supports_method :textDocument/codeAction)
          (each [_ action (ipairs actions)]
            (vim.lsp.buf.code_action {:context {:only [action]} :apply true}))))))

(fn org-ts-imports []
  (let [bufnr (vim.api.nvim_get_current_buf)
        clients (vim.lsp.get_clients {: bufnr})]
    (each [_ client (ipairs clients)]
      (if (= client.name :ts_ls)
          (client:exec_cmd {:arguments [(vim.uri_from_bufnr bufnr)]
                            :command :_typescript.organizeImports})))))

(fn au [group-name commands]
  (let [group (vim.api.nvim_create_augroup group-name {:clear true})
        c #(vim.api.nvim_create_autocmd $1 {:callback $2 : group :buffer 0})]
    (each [ev cmd (pairs commands)] (c ev cmd))
    group))

(fn set-highlight []
  (au :Highlight {[:CursorHold :CursorHoldI] vim.lsp.buf.document_highlight
                  :CursorMoved vim.lsp.buf.clear_references}))

(fn inside-call-args? []
  (let [node (vim.treesitter.get_node)]
    (var cur node)
    (var found? false)
    (while (and cur (not found?))
      (let [t (cur:type)]
        (if (or (= t :argument_list) (= t :call_expression))
            (set found? true))
        (set cur (cur:parent))))
    found?))

(fn lsp-hints-toggle [val]
  (if vim.b.hints_on (vim.lsp.inlay_hint.enable val {:bufnr 0})))

(fn lsp-format [_args]
  (vim.lsp.buf.format {:filter #(not= $.name :ts_ls)}))

(fn on-attach [args]
  (let [client_id args.data.client_id
        client (vim.lsp.get_client_by_id client_id)
        buffer args.buf]
    (set vim.b.offset_encoding client.offset_encoding)
    (vim.cmd.LspKeysMap buffer)
    (when (client:supports_method :textDocument/inlayHint)
      (set vim.b.hints_on true)
      (set vim.b.hints false)
      (vim.lsp.inlay_hint.enable vim.b.hints))
    (if (client:supports_method :textDocument/documentHighlight)
        (set-highlight))
    (if (client:supports_method :textDocument/completion)
        (vim.lsp.completion.enable true client.id args.buf {:autotrigger false}))
    (when (client:supports_method :textDocument/codeLens)
      (au :CodeLens
          {[:BufEnter :CursorHold :InsertLeave] vim.lsp.codelens.refresh})
      (vim.defer_fn vim.lsp.codelens.refresh 100))
    (if (client:supports_method :textDocument/signatureHelp)
        (au :LSPSignatureHelp
            {[:TextChangedI] #(if (inside-call-args?)
                                  (vim.lsp.buf.signature_help))}))
    (if (client:supports_method :textDocument/onTypeFormatting)
        (vim.lsp.on_type_formatting.enable true {: client_id}))
    false))

;TODO Should we add :refactor :quickfix ?
(let [global-ca [:source.organizeImports :source.fixAll]
      code-actions #(apply-code-actions global-ca)
      group (vim.api.nvim_create_augroup :LSP {:clear true})
      au #(vim.api.nvim_create_autocmd $1 (vim.tbl_extend :force $2 {: group}))]
  (au :BufWritePre {:callback lsp-format :desc "Format on save"})
  (au :BufWritePre {:callback code-actions :desc "Organize imports on save"})
  (au :BufWritePre {:callback org-ts-imports
                    :pattern "*.ts,*.tsx,*.js,*.jsx"
                    :desc "Organize TS imports on save"})
  (au :InsertEnter
      {:callback #(lsp-hints-toggle false)
       :desc "Disable LSP hints on insert enter"})
  (au :InsertLeave
      {:callback #(lsp-hints-toggle vim.b.hints)
       :desc "Enable LSP hints on insert leave"})
  (au :LspAttach {:callback on-attach}))
