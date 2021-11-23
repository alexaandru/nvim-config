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
            :r_language_server {}
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

(fn set-keys []
  (each [c1 kx (pairs keys)]
    (each [c2 key (pairs kx)]
      (let [fmt string.format ;;
            ;; https://github.com/neovim/neovim/pull/15585
            scope (if (= c1 :diagnostic) "" :lsp.)
            cmd (fmt "<Cmd>lua vim.%s%s.%s()<CR>" scope c1 c2)
            ns {:noremap true :silent true}
            māp #(vim.api.nvim_buf_set_keymap 0 :n $1 $2 ns)]
        (māp key cmd)))))

(local {: au} (require :setup))

(fn set-highlight []
  (au {:Highlight ["CursorHold <buffer> lua vim.lsp.buf.document_highlight()"
                   "CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()"
                   "CursorMoved <buffer> lua vim.lsp.buf.clear_references()"]}))

(fn on_attach [client bufnr]
  (set-keys)
  (let [rc client.resolved_capabilities]
    (if rc.document_highlight (set-highlight))
    (if rc.code_lens
        (au {:CodeLens ["BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()"]}))
    (if rc.code_action
        (au {:CodeActions ["CursorHold,CursorHoldI <buffer> lua Lightbulb()"]}))
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
  (au {:Format ["BufWritePre *.go lua OrgImports()"
                "BufWritePre *.js,*.jsx lua OrgJSImports()"
                "BufWritePre * lua Format()"]}))

{: on_attach : setup}

