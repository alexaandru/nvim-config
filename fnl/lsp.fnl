(local util (require :util))
(local keys (. (require :config.keys) :lsp))
(local lsp {;; lspconfig setup() arguments, as defined at
            ;; https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md
            :cfg {:bashls {}
                  :cssls {}
                  :dockerls {}
                  :efm (require :config.efm)
                  :elixirls (require :config.elixirls)
                  :erlangls (require :config.noformat)
                  :gopls (require :config.gopls)
                  :html {}
                  :jsonls (require :config.noformat)
                  :pylsp {}
                  :r_language_server nil
                  :solargraph nil
                  :sumneko_lua (require :config.sumneko)
                  :terraformls (require :config.tf)
                  :tflint {}
                  :tsserver (require :config.noformat)
                  :vimls nil
                  :vuels {}
                  :yamlls {}}
            :dia {;gnostics
                  :underline true
                  :virtual_text {:spacing 5 :prefix "🚩"}
                  :signs true
                  :update_in_insert true}})

(fn set_keys []
  (let [ns {:noremap true :silent true}]
    (each [c1 kx (pairs keys)]
      (each [c2 key (pairs kx)]
        (let [cmd (string.format "<Cmd>lua vim.lsp.%s.%s()<CR>" c1 c2)]
          (vim.api.nvim_buf_set_keymap 0 :n key cmd ns))))))

(fn set_highlight []
  (au {:Highlight ["CursorHold <buffer> lua vim.lsp.buf.document_highlight()"
                   "CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()"
                   "CursorMoved <buffer> lua vim.lsp.buf.clear_references()"]}))

(fn lsp.on_attach [client bufnr]
  (set_keys)
  (let [rc client.resolved_capabilities]
    (if rc.document_highlight (set_highlight))
    (if rc.code_lens
        (au {:CodeLens ["BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()"]}))
    (if rc.completion (set vim.bo.omnifunc "v:lua.vim.lsp.omnifunc")))
  (let [lsa (. (require :lsp_signature) :on_attach)]
    (lsa (require :config.lsp_signature))))

(fn lsp.setup []
  (vim.cmd "aug LSP | au!")
  (local lspc (require :lspconfig))
  (local cfg_default {:on_attach lsp.on_attach
                      :flags {:debounce_text_changes 150}})
  (each [k cfg (pairs lsp.cfg)]
    (let [setup (. (. lspc k) :setup)]
      (setup (vim.tbl_extend :keep cfg cfg_default))))
  (vim.cmd "aug END")
  (let [opd vim.lsp.diagnostic.on_publish_diagnostics]
    (tset vim.lsp.handlers :textDocument/publishDiagnostics
          (vim.lsp.with opd lsp.dia)))
  (au {:Format ["BufWritePre *.go lua OrgImports()"
                "BufWritePre *.js,*.jsx lua OrgJSImports()"
                "BufWritePre * lua Format()"]}))

lsp

