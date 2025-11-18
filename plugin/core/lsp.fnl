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
        :grci vim.lsp.buf.incoming_calls
        :grco vim.lsp.buf.outgoing_calls
        :gOO workspace-symbol
        :<Leader>wla vim.lsp.buf.add_workspace_folder
        :<Leader>wlr vim.lsp.buf.remove_workspace_folder
        :<Leader>wll #(print (vim.inspect (vim.fn.uniq (vim.fn.sort (vim.lsp.buf.list_workspace_folders)))))})

(var lsp-progress-info "")

(fn get-lsp-progress []
  lsp-progress-info)

(set _G.get_lsp_progress get-lsp-progress)

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

(fn progress-handler [err result _ctx]
  (if (and (not err) result result.value)
      (let [kind result.value.kind
            msg (or result.value.message "")
            pct result.value.percentage
            title result.value.title
            token result.token
            ft vim.bo.filetype
            out (if (= ft :rust) token title)]
        (set lsp-progress-info
             (if (= kind :end) ""
                 (.. "   🔄 " out
                     (if (and pct (> pct 0)) (.. " (" pct "%" ")")
                         (> (length msg) 0) (.. " :: " msg)
                         ""))))
        (vim.schedule #(vim.cmd.redrawtabline)))))

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

(fn on-attach [args]
  (let [client_id args.data.client_id
        client (vim.lsp.get_client_by_id client_id)
        buffer args.buf]
    (set vim.b.offset_encoding client.offset_encoding)
    (let [opts {:silent true : buffer}]
      (each [lhs rhs (pairs lsp-keys)] (vim.keymap.set :n lhs rhs opts)))
    (when (client:supports_method :textDocument/inlayHint)
      (vim.lsp.inlay_hint.enable false)
      (set vim.b.hints_on true))
    (if (client:supports_method :textDocument/documentHighlight)
        (set-highlight))
    (if (client:supports_method :textDocument/completion)
        (vim.lsp.completion.enable true client.id args.buf {:autotrigger true}))
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
    (if (client:supports_method :$/progress)
        (set client.handlers.$/progress progress-handler))
    false))

(vim.diagnostic.config {:underline true
                        :virtual_text {:spacing 0 :prefix "‼"}
                        :signs {:text {vim.diagnostic.severity.ERROR "✘"
                                       vim.diagnostic.severity.WARN "⚠"
                                       vim.diagnostic.severity.INFO "i"
                                       vim.diagnostic.severity.HINT "h"}}
                        :update_in_insert true
                        :severity_sort true
                        :float {:border :rounded
                                :source true
                                :suffix " "
                                :severity_sort true
                                :header ""}})

(vim.lsp.inline_completion.enable true)
(vim.keymap.set :i :<Tab> #(if (not (vim.lsp.inline_completion.get)) :<Tab>)
                {:desc "Get the current inline completion"
                 :expr true
                 :replace_keycodes true})

(vim.keymap.set :n :<Tab> #(if (not ((. (require :sidekick) :nes_jump_or_apply)))
                               :<Tab>)
                {:desc "Get the next inline completion (via Sidekick)"
                 :expr true
                 :replace_keycodes true})

(vim.keymap.set :i :<C-n> #(vim.lsp.inline_completion.select {:count 1})
                {:desc "Get the next inline completion"})

(vim.keymap.set :i :<C-i> #(vim.lsp.buf.signature_help)
                {:desc "Show signature help"})

(vim.lsp.log.set_level vim.log.levels.ERROR)

;:refactor :quickfix
(local global-ca [:source.organizeImports :source.fixAll])

(let [group (vim.api.nvim_create_augroup :LSP {:clear true})
      au #(vim.api.nvim_create_autocmd :BufWritePre
                                       {: group
                                        :callback $1
                                        :pattern $2
                                        :desc $3})]
  (au #(let [bufnr (vim.api.nvim_get_current_buf)
             clients (vim.lsp.get_clients {: bufnr})]
         (each [_ client (ipairs clients)]
           (if (client:supports_method :textDocument/formatting)
               (vim.lsp.buf.format {:async false :filter #(not= $.name :ts_ls)}))))
      nil "Format on save")
  (au #(apply-code-actions global-ca) nil "Organize imports on save")
  (au org-ts-imports "*.ts,*.tsx,*.js,*.jsx" "Organize TS imports on save"))

(vim.api.nvim_create_autocmd :LspAttach {:group :LSP :callback on-attach})
;(vim.api.nvim_create_autocmd :LspTokenUpdate {:group :LSP :callback #(print (vim.inspect $1))})
