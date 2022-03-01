(local cfg {:bashls {}
            :cssls {}
            :dockerls {}
            :efm (require :config.efm)
            ;:elixirls (require :config.elixirls)
            ;:erlangls (require :config.noformat)
            ;:elmls {}
            :gopls (require :config.gopls)
            :html {}
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
            :tsserver (require :config.noformat)
            ;:vimls nil
            :vuels {}
            :yamlls {}})

(local dia {;gnostics
            :underline true
            :virtual_text {:spacing 1 :prefix "🚩"}
            :signs true
            :update_in_insert true
            :severity_sort true})

(local {:lsp keys} (require :config.keys))

(local wait-default 2000)

(fn Format [wait-ms]
  (vim.lsp.buf.formatting_sync nil (or wait-ms wait-default)))

(fn Lightbulb []
  (let [{: update_lightbulb} (require :nvim-lightbulb)]
    (update_lightbulb {:sign {:enabled false}
                       :virtual_text {:enabled true :text "💡"}})))

;; Synchronously organise imports, courtesy of
;; https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-656372575 and
;; https://github.com/lucax88x/configs/blob/master/dotfiles/.config/nvim/lua/lt/lsp/functions.lua
(fn OrgImports [wait-ms]
  (let [params (vim.lsp.util.make_range_params)]
    (set params.context {:only [:source.organizeImports]})
    (let [result (vim.lsp.buf_request_sync 0 :textDocument/codeAction params
                                           (or wait-ms wait-default))]
      (each [_ res (pairs (or result {}))]
        (each [_ r (pairs (or res.result {}))]
          (if r.edit
              (vim.lsp.util.apply_workspace_edit r.edit vim.b.offset_encoding)
              (vim.lsp.buf.execute_command r.command)))))))

(fn OrgJSImports []
  (vim.lsp.buf.execute_command {:arguments [(vim.fn.expand "%:p")]
                                :command :_typescript.organizeImports}))

(fn set-keys []
  (each [c1 kx (pairs keys)]
    (each [c2 key (pairs kx)]
      (let [fmt string.format ;;
            ;; https://github.com/neovim/neovim/pull/15585
            scope (if (= c1 :diagnostic) vim.diagnostic (. vim.lsp c1))
            cmd (. scope c2)
            desc (fmt "vim%s.%s.%s()" (if (= c1 :diagnostic) "" :.lsp) c1 c2)
            ns {:silent true :buffer true : desc}
            māp #(vim.keymap.set :n $1 $2 ns)]
        (māp key cmd)))))

(local {: au} (require :setup))

(fn set-highlight []
  (au {:Highlight [[:CursorHold vim.lsp.buf.document_highlight 0]
                   [:CursorHoldI vim.lsp.buf.document_highlight 0]
                   [:CursorMoved vim.lsp.buf.clear_references 0]]}))

(fn on_attach [client bufnr]
  (set vim.b.offset_encoding client.offset_encoding)
  (set-keys)
  (let [rc client.resolved_capabilities]
    (if rc.document_highlight (set-highlight))
    (if rc.code_lens
        (au {:CodeLens [[[:BufEnter :CursorHold :InsertLeave]
                         vim.lsp.codelens.refresh
                         0]]}))
    (if rc.code_action
        (au {:CodeActions [[[:CursorHold :CursorHoldI] Lightbulb 0]]}))
    (if rc.completion (set vim.bo.omnifunc "v:lua.vim.lsp.omnifunc"))))

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

