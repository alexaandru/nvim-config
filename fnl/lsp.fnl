(local cfg {:bashls {}
            :cssls {}
            :dockerls {}
            :efm (require :config.efm)
            ;:elixirls (require :config.elixirls)
            ;:erlangls (require :config.noformat)
            ;:elmls {}
            :gopls (require :config.gopls)
            :html (require :config.noformat)
            :jsonls (require :config.noformat)
            ;:nimls {}
            ;:purescriptls {}
            :pylsp {}
            ;:r_language_server {}
            ;:rescriptls (require :config.rescript)
            ;:solargraph {}
            ;:sumneko_lua (require :config.sumneko)
            :terraformls (require :config.tf)
            :tflint {}
            :tsserver (require :config.tsserver)
            ;:vimls nil
            :vuels {}
            :yamlls {}})

(local dia {;gnostics
            :underline true
            :virtual_text {:spacing 1 :prefix "⏹"}
            :signs true
            :update_in_insert false
            :severity_sort true})

(local wait-ms 1200)

(fn Format []
  (vim.lsp.buf.format {:timeout-ms wait-ms}))

(fn Lightbulb []
  (let [{: update_lightbulb} (require :nvim-lightbulb)]
    (update_lightbulb {:sign {:enabled false}
                       :virtual_text {:enabled true :text "💡"}})))

;; Synchronously organise imports, courtesy of
;; https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-656372575 and
;; https://github.com/lucax88x/configs/blob/master/dotfiles/.config/nvim/lua/lt/lsp/functions.lua
(fn OrgImports []
  (let [ms wait-ms
        params (vim.lsp.util.make_range_params)]
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
    (if rc.codeActionProvider
        (au {:CodeActions [[[:CursorHold :CursorHoldI] Lightbulb 0]]}))
    (when rc.completionProvider
      (set vim.bo.omnifunc "v:lua.vim.lsp.omnifunc")
      ((. (require :lsp_compl) :attach) client bufnr))
    (if rc.definitionProvider (set vim.bo.tagfunc "v:lua.vim.lsp.tagfunc"))))

(fn setup []
  (vim.cmd "aug LSP | au!")
  (let [lspc (require :lspconfig)
        cfg-default {: on_attach :flags {:debounce_text_changes 150}}]
    (each [k cfg (pairs cfg)]
      (let [{: setup} (. lspc k)
            cfg (vim.tbl_extend :keep cfg cfg-default)]
        (setup cfg))))
  (vim.cmd "aug END")
  (let [opd vim.lsp.diagnostic.on_publish_diagnostics]
    (tset vim.lsp.handlers :textDocument/publishDiagnostics
          (vim.lsp.with opd dia)))
  (au {:Format [[:BufWritePre OrgImports :*.go]
                [:BufWritePre OrgJSImports "*.js,*.jsx"]
                [:BufWritePre Format]]}))

{: on_attach : setup}

