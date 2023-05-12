(local lsp-keys {:<F2> vim.lsp.buf.rename
                 :<Leader>a vim.lsp.buf.code_action
                 :<Leader>D vim.diagnostic.setqflist
                 :<Leader>k vim.lsp.codelens.run
                 :<Leader>e vim.diagnostic.open_float})

;; fnlfmt: skip
(fn OrgImports []
  (vim.lsp.buf.code_action {:context {:only [:source.organizeImports]} :apply true})
  (vim.lsp.buf.code_action {:context {:only [:source.fixAll]} :apply true}))

(fn OrgJSImports []
  (vim.lsp.buf.execute_command {:arguments [(vim.fn.expand "%:p")]
                                :command :_typescript.organizeImports}))

(fn au [group-name commands]
  (let [group (vim.api.nvim_create_augroup group-name {:clear true})
        c #(vim.api.nvim_create_autocmd $1 {:callback $2 : group :buffer 0})]
    (each [ev cmd (pairs commands)] (c ev cmd))
    group))

(fn set-highlight []
  (au :Highlight {[:CursorHold :CursorHoldI] vim.lsp.buf.document_highlight
                  :CursorMoved vim.lsp.buf.clear_references}))

(fn on-attach [args]
  (let [client (vim.lsp.get_client_by_id args.data.client_id)
        buffer args.buf]
    (set vim.b.offset_encoding client.offset_encoding)
    (let [opts {:silent true : buffer}]
      (each [lhs rhs (pairs lsp-keys)] (vim.keymap.set :n lhs rhs opts)))
    (when (client:supports_method :textDocument/inlayHint)
      (vim.lsp.inlay_hint.enable false)
      (set vim.b.hints_on true))
    (if (client:supports_method :textDocument/documentHighlight)
        (set-highlight))
    ;; TODO: How to check for code lenses capability?
    (au :CodeLens
        {[:BufEnter :CursorHold :InsertLeave] vim.lsp.codelens.refresh})
    ;; callbacks that return a truthy value cause the autocmd to be deleted!!!
    false))

;; fnlfmt: skip
(each [_ name (ipairs (vim.fn.globpath (.. (vim.fn.stdpath :config) "/fnl/lsp") :*.fnl false true))]
  (let [name (vim.fn.fnamemodify name ":t:r")]
    (tset vim.lsp.config name (require name))
    (vim.lsp.enable name)))

(vim.diagnostic.config {:underline true
                        :virtual_text {:spacing 0 :prefix "‼"}
                        :signs true
                        :update_in_insert true
                        :severity_sort true
                        :float {:border :rounded
                                :source true
                                :suffix " "
                                :severity_sort true
                                :header ""}})

(vim.lsp.inline_completion.enable true)
(vim.keymap.set :i :<Tab> #(when (not (vim.lsp.inline_completion.get)) :<Tab>)
                {:desc "Get the current inline completion"
                 :expr true
                 :replace_keycodes true})

(vim.lsp.log.set_level vim.lsp.log.levels.ERROR)

(set vim.lsp.handlers.textDocument/hover
     (vim.lsp.with vim.lsp.handlers.hover {:border :rounded}))

(let [group (vim.api.nvim_create_augroup :LSP {:clear true})
      au #(vim.api.nvim_create_autocmd :BufWritePre
                                       {: group :callback $1 :pattern $2})]
  (au #(vim.lsp.buf.format {:async false}))
  (au OrgImports :*.go)
  (au OrgJSImports "*.js,*.jsx"))

(vim.api.nvim_create_autocmd :LspAttach {:group :LSP :callback on-attach})
;(vim.api.nvim_create_autocmd :LspTokenUpdate {:group :LSP :callback #(print (vim.inspect $1))})
