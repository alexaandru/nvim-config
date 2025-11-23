(fn workspace-symbol []
  (let [cword (vim.fn.expand :<cword>)]
    (if (= cword "")
        (vim.lsp.buf.workspace_symbol)
        (vim.lsp.buf.workspace_symbol cword))))

(local lsp-keys
       {:<F2> vim.lsp.buf.rename
        :<Leader>a vim.lsp.buf.code_action
        :<Leader>d vim.diagnostic.setloclist
        :<Leader>D vim.diagnostic.setqflist
        :<Leader>k vim.lsp.codelens.run
        :<Leader>e vim.diagnostic.open_float
        :<Leader>h #(vim.cmd :LspHintsToggle)
        :grci vim.lsp.buf.incoming_calls
        :grco vim.lsp.buf.outgoing_calls
        :gOO workspace-symbol
        :<Leader>wla vim.lsp.buf.add_workspace_folder
        :<Leader>wlr vim.lsp.buf.remove_workspace_folder
        :<Leader>wll #(print (vim.inspect (vim.fn.uniq (vim.fn.sort (vim.lsp.buf.list_workspace_folders)))))})

(vim.lsp.inline_completion.enable true)
(vim.lsp.document_color.enable)
(vim.lsp.log.set_level vim.log.levels.ERROR)

;; fnlfmt: skip
(vim.diagnostic.config (let [s vim.diagnostic.severity]
                         {:underline true
                          :virtual_text {:spacing 0 :prefix "‼"}
                          :signs {:text {s.ERROR "✘" s.WARN "⚠" s.INFO "i" s.HINT "h"}}
                          :update_in_insert true
                          :severity_sort true
                          :float {:border :rounded :source true :suffix " " 
                          :severity_sort true :header ""}}))

(var lsp-progress-info "")

(fn vim.g.get_lsp_progress []
  lsp-progress-info)

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

;; TODO: reconcile this with the one in let at the end.
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

(fn lsp-format [args]
  (let [bufnr args.buf
        clients (vim.lsp.get_clients {: bufnr})]
    (each [_ client (ipairs clients)]
      (if (client:supports_method :textDocument/formatting)
          (vim.lsp.buf.format {:async false :filter #(not= $.name :ts_ls)})))))

(fn on-attach [args]
  (let [client_id args.data.client_id
        client (vim.lsp.get_client_by_id client_id)
        buffer args.buf]
    (set vim.b.offset_encoding client.offset_encoding)
    (let [opts {:silent true : buffer}]
      (each [lhs rhs (pairs lsp-keys)] (vim.keymap.set :n lhs rhs opts)))
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

(let [imap #(vim.keymap.set :i $1 $2 $3)
      nmap #(vim.keymap.set :n $1 $2 $3)]
  (imap :<Tab> #(if (not (vim.lsp.inline_completion.get)) :<Tab>)
        {:desc "Get the current inline completion"
         :expr true
         :replace_keycodes true})
  (nmap :<Tab> #(if (not ((. (require :sidekick) :nes_jump_or_apply))) :<Tab>)
        {:desc "Get the next inline completion (via Sidekick)"
         :expr true
         :replace_keycodes true})
  (imap :<C-n> #(vim.lsp.inline_completion.select {:count 1})
        {:desc "Get the next inline completion"})
  (imap :<C-i> #(vim.lsp.buf.signature_help) {:desc "Show signature help"}))
