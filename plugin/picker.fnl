(local picker (require :picker))
(local findfunc _G.Fd_findfunc)
(local (has-devicons devicons) (pcall require :nvim-web-devicons))

(fn set-file-icons [buf lines]
  (when has-devicons
    (let [ns (vim.api.nvim_create_namespace :file-picker-icons)]
      ;; Clear existing extmarks first
      (vim.api.nvim_buf_clear_namespace buf ns 0 -1)
      (each [i line (ipairs lines)]
        (if (and line (not= line ""))
            (let [(icon color) (devicons.get_icon (vim.fn.fnamemodify line ":t"))
                  (fallback-icon fallback-color) (devicons.get_icon "default.txt")
                  final-icon (or icon fallback-icon)
                  final-color (or color fallback-color "Normal")]
              (vim.api.nvim_buf_set_extmark buf ns (- i 1) 0
                                            {:virt_text [[(.. " " final-icon
                                                              " ")
                                                          final-color]]
                                             :virt_text_pos :inline})))))))

(fn is-binary-file [filepath]
  (let [file (io.open filepath "rb")]
    (if file
        (let [content (file:read 1024)] ; Read first 1024 bytes
          (file:close)
          (and content (string.find content "\0")))
        false)))

(fn file-preview [filepath]
  (if (vim.fn.filereadable filepath)
      (if (is-binary-file filepath)
          ["[Binary file]"]
          (let [lines (vim.fn.readfile filepath)]
            (if (> (length lines) 0)
                lines
                ["[Empty file]"])))
      ["[File not readable]"]))

(fn open-file [filepath _]
  (if filepath
      (vim.cmd.edit filepath)))

(fn file-picker []
  (picker (fn [filter _]
            (findfunc filter _))
          {:preview-fn file-preview
           :on-select open-file
           :setup-list-fn (fn [buf lines]
                            (set-file-icons buf lines))
           :config {:prompt "Find File: "
                    :width 140
                    :height 35
                    :preview {:enabled true :width-ratio 0.55 :treesitter true}
                    :fuzzy {:enabled true :limit 30 :matchseq 0}}}))

(fn simple-file-picker []
  (picker (fn [filter _]
            (findfunc filter _))
          {:on-select open-file
           :setup-list-fn (fn [buf lines]
                            (set-file-icons buf lines))
           :config {:prompt "Find File (No Preview): "
                    :preview {:enabled false}
                    :fuzzy {:enabled true :limit 50 :matchseq 0}}}))

(fn source-filter-picker []
  (picker findfunc {:preview-fn file-preview
                    :on-select open-file
                    :setup-list-fn (fn [buf lines]
                                     (set-file-icons buf lines))
                    :config {:prompt "Find File (Source Filter): "
                             :preview {:treesitter true}
                             :fuzzy {:enabled false}}}))

(fn file-picker-basename []
  (picker (fn [filter _]
            (findfunc filter _))
          {:preview-fn file-preview
           :on-select open-file
           :setup-list-fn (fn [buf lines]
                            (set-file-icons buf lines))
           :config {:prompt "Find File (Basename): "
                    :preview {:treesitter true}
                    :fuzzy {:enabled true
                            :limit 30
                            :matchseq 0
                            :key "fnamemodify(v:val, ':t')"}}}))

(fn buffer-source [filter _]
  (let [buffers []
        all-bufs (vim.api.nvim_list_bufs)]
    (each [_ buf (ipairs all-bufs)]
      (if (vim.api.nvim_buf_is_loaded buf)
          (let [name (vim.api.nvim_buf_get_name buf)
                bufname (if (= name "") "[No Name]"
                            (vim.fn.fnamemodify name ":t"))]
            (table.insert buffers bufname))))
    ;; Filter buffers if filter text provided
    (if (= (length filter) 0)
        buffers
        (vim.fn.matchfuzzy buffers filter {:limit 20}))))

(fn buffer-preview [bufname]
  (let [all-bufs (vim.api.nvim_list_bufs)]
    (var target-buf nil)
    (each [_ buf (ipairs all-bufs)]
      (if (vim.api.nvim_buf_is_loaded buf)
          (let [name (vim.api.nvim_buf_get_name buf)
                display-name (if (= name "") "[No Name]"
                                 (vim.fn.fnamemodify name ":t"))]
            (if (= display-name bufname)
                (set target-buf buf)))))
    (if target-buf
        (vim.api.nvim_buf_get_lines target-buf 0 30 false)
        ["[Buffer not found]"])))

(fn switch-to-buffer [bufname _]
  (let [all-bufs (vim.api.nvim_list_bufs)]
    (each [_ buf (ipairs all-bufs)]
      (if (vim.api.nvim_buf_is_loaded buf)
          (let [name (vim.api.nvim_buf_get_name buf)
                display-name (if (= name "") "[No Name]"
                                 (vim.fn.fnamemodify name ":t"))]
            (if (= display-name bufname)
                (vim.api.nvim_set_current_buf buf)))))))

(fn buffer-picker []
  (picker buffer-source
          {:preview-fn buffer-preview
           :on-select switch-to-buffer
           :config {:prompt "Switch Buffer: "
                    :width 120
                    :height 25
                    :fuzzy {:enabled true :limit 20 :matchseq 0}}}))

(vim.api.nvim_create_user_command :PickFile file-picker {})
(vim.api.nvim_create_user_command :PickFileSimple simple-file-picker {})
(vim.api.nvim_create_user_command :PickFileSource source-filter-picker {})
(vim.api.nvim_create_user_command :PickFileBasename file-picker-basename {})
(vim.api.nvim_create_user_command :PickBuffer buffer-picker {})

;; LSP-based pickers
(fn lsp-symbols-source [filter _]
  (let [symbols []]
    (if (next (vim.lsp.get_clients {:bufnr 0}))
        (let [params {:textDocument (vim.lsp.util.make_text_document_params)}
              results (vim.lsp.buf_request_sync 0 "textDocument/documentSymbol"
                                                params 1000)]
          (each [_ result (pairs (or results {}))]
            (when result.result
              (fn flatten-symbols [syms prefix]
                (each [_ sym (ipairs syms)]
                  (let [name (string.gsub (.. (or prefix "") sym.name) "\n" " ")
                        kind (. vim.lsp.protocol.SymbolKind sym.kind)
                        line (+ sym.range.start.line 1)]
                    (table.insert symbols (.. name " [" kind "] :" line))
                    (if sym.children
                        (flatten-symbols sym.children (.. name "."))))))

              (flatten-symbols result.result)))))
    (if (= (length filter) 0)
        symbols
        (vim.fn.matchfuzzy symbols filter {:limit 50}))))

(fn lsp-symbols-preview [item]
  (let [line-match (string.match item ":(%d+)$")]
    (if line-match
        (let [line-num (tonumber line-match)
              current-buf (vim.api.nvim_get_current_buf)
              lines (vim.api.nvim_buf_get_lines current-buf
                                                (math.max 0 (- line-num 5))
                                                (+ line-num 10) false)]
          lines)
        ["[Could not parse symbol location]"])))

(fn lsp-symbols-select [item _]
  (let [line-match (string.match item ":(%d+)$")]
    (if line-match
        (let [line-num (tonumber line-match)]
          (vim.api.nvim_win_set_cursor 0 [line-num 0])
          (vim.cmd "normal! zz")))))

(fn lsp-symbols-picker []
  (if (next (vim.lsp.get_clients {:bufnr 0}))
      (picker lsp-symbols-source
              {:preview-fn lsp-symbols-preview
               :on-select lsp-symbols-select
               :config {:prompt "LSP Symbols: "
                        :width 120
                        :height 30
                        :fuzzy {:enabled true :limit 50 :matchseq 0}}})
      (vim.notify "No LSP client attached" vim.log.levels.WARN)))

(fn lsp-workspace-symbols-source [filter _]
  (let [symbols []]
    (if (next (vim.lsp.get_clients {:bufnr 0}))
        (let [params {:query (or filter "")}
              results (vim.lsp.buf_request_sync 0 "workspace/symbol" params
                                                2000)]
          (each [_ result (pairs (or results {}))]
            (if result.result
                (each [_ sym (ipairs result.result)]
                  (let [name (string.gsub sym.name "\n" " ")
                        kind (. vim.lsp.protocol.SymbolKind sym.kind)
                        file (vim.uri_to_fname sym.location.uri)
                        line (+ sym.location.range.start.line 1)]
                    (table.insert symbols
                                  (.. name " [" kind "] " file ":" line))))))))
    symbols))

(fn lsp-workspace-symbols-preview [item]
  (let [file-match (string.match item " ([^:]+):(%d+)$")]
    (if file-match
        (let [filepath (string.match item " ([^:]+):%d+$")
              line-num (tonumber (string.match item ":(%d+)$"))]
          (if (vim.fn.filereadable filepath)
              (let [lines (vim.fn.readfile filepath (+ line-num 10)
                                           (math.max 1 (- line-num 5)))]
                (if (> (length lines) 0) lines ["[Empty file]"]))
              ["[File not readable]"]))
        ["[Could not parse location]"])))

(fn lsp-workspace-symbols-select [item _]
  (let [filepath (string.match item " ([^:]+):%d+$")
        line-num (tonumber (string.match item ":(%d+)$"))]
    (when (and filepath line-num)
      (vim.cmd.edit filepath)
      (vim.api.nvim_win_set_cursor 0 [line-num 0])
      (vim.cmd "normal! zz"))))

(fn lsp-workspace-symbols-picker []
  (if (next (vim.lsp.get_clients {:bufnr 0}))
      (picker lsp-workspace-symbols-source
              {:preview-fn lsp-workspace-symbols-preview
               :on-select lsp-workspace-symbols-select
               :config {:prompt "Workspace Symbols: "
                        :width 140
                        :height 35
                        :fuzzy {:enabled false}}})
      (vim.notify "No LSP client attached" vim.log.levels.WARN)))

(fn lsp-diagnostics-source [filter _]
  (let [diagnostics []
        diag-list (vim.diagnostic.get)]
    (each [_ diag (ipairs diag-list)]
      (let [severity (. vim.diagnostic.severity diag.severity)
            file (vim.api.nvim_buf_get_name diag.bufnr)
            line (+ diag.lnum 1)
            message (string.gsub diag.message "\n" " ")]
        (table.insert diagnostics (.. "[" severity "] " message " @ " file ":"
                                      line))))
    (if (= (length filter) 0)
        diagnostics
        (vim.fn.matchfuzzy diagnostics filter {:limit 50}))))

(fn lsp-diagnostics-preview [item]
  (let [filepath (string.match item " @ ([^:]+):%d+$")
        line-num (tonumber (string.match item ":(%d+)$"))]
    (if (and filepath line-num (vim.fn.filereadable filepath))
        (let [lines (vim.fn.readfile filepath)]
          (if (and (> (length lines) 0) (<= line-num (length lines)))
              (vim.list_slice lines (math.max 1 (- line-num 3))
                              (math.min (length lines) (+ line-num 3)))
              ["[Line out of range]"]))
        ["[File not readable]"])))

(fn lsp-diagnostics-select [item _]
  (let [filepath (string.match item " @ ([^:]+):%d+$")
        line-num (tonumber (string.match item ":(%d+)$"))]
    (when (and filepath line-num)
      (vim.cmd.edit filepath)
      (vim.api.nvim_win_set_cursor 0 [line-num 0])
      (vim.cmd "normal! zz"))))

(fn lsp-diagnostics-picker []
  (let [diag-count (length (vim.diagnostic.get))]
    (if (> diag-count 0)
        (picker lsp-diagnostics-source
                {:preview-fn lsp-diagnostics-preview
                 :on-select lsp-diagnostics-select
                 :config {:prompt "Diagnostics: "
                          :width 140
                          :height 30
                          :fuzzy {:enabled true :limit 50 :matchseq 0}}})
        (vim.notify "No diagnostics found" vim.log.levels.INFO))))

(fn lsp-references-source [filter _]
  (let [references []]
    (if (next (vim.lsp.get_clients {:bufnr 0}))
        (let [params (vim.lsp.util.make_position_params)
              _ (set params.context {:includeDeclaration true})
              results (vim.lsp.buf_request_sync 0 "textDocument/references"
                                                params 2000)]
          (each [_ result (pairs (or results {}))]
            (if result.result
                (each [_ ref (ipairs result.result)]
                  (let [file (vim.uri_to_fname ref.uri)
                        line (+ ref.range.start.line 1)
                        col (+ ref.range.start.character 1)]
                    (table.insert references (.. file ":" line ":" col))))))))
    (if (= (length filter) 0)
        references
        (vim.fn.matchfuzzy references filter {:limit 50}))))

(fn lsp-references-preview [item]
  (let [filepath (string.match item "^([^:]+):")
        line-num (tonumber (string.match item ":(%d+):"))]
    (if (and filepath line-num (vim.fn.filereadable filepath))
        (let [lines (vim.fn.readfile filepath)]
          (if (and (> (length lines) 0) (<= line-num (length lines)))
              (vim.list_slice lines (math.max 1 (- line-num 3))
                              (math.min (length lines) (+ line-num 3)))
              ["[Line out of range]"]))
        ["[File not readable]"])))

(fn lsp-references-select [item _]
  (let [filepath (string.match item "^([^:]+):")
        line-num (tonumber (string.match item ":(%d+):"))
        col-num (tonumber (string.match item ":(%d+)$"))]
    (when (and filepath line-num col-num)
      (vim.cmd.edit filepath)
      (vim.api.nvim_win_set_cursor 0 [line-num col-num])
      (vim.cmd "normal! zz"))))

(fn lsp-references-picker []
  (if (next (vim.lsp.get_clients {:bufnr 0}))
      (picker lsp-references-source
              {:preview-fn lsp-references-preview
               :on-select lsp-references-select
               :config {:prompt "References: "
                        :width 140
                        :height 35
                        :fuzzy {:enabled true :limit 50 :matchseq 0}}})
      (vim.notify "No LSP client attached" vim.log.levels.WARN)))

;; fnlfmt: skip
(vim.api.nvim_create_autocmd :LspAttach
     {:callback #(let [bufnr $.buf opts {:buffer bufnr :silent true}]
                   (vim.keymap.set :n :<leader>ls lsp-symbols-picker opts)
                   (vim.keymap.set :n :<leader>lw lsp-workspace-symbols-picker opts)
                   (vim.keymap.set :n :<leader>ld lsp-diagnostics-picker opts)
                   (vim.keymap.set :n :<leader>lr lsp-references-picker opts))})

(vim.api.nvim_create_user_command :PickFile file-picker {})
(vim.api.nvim_create_user_command :PickFileSimple simple-file-picker {})
(vim.api.nvim_create_user_command :PickFileSource source-filter-picker {})
(vim.api.nvim_create_user_command :PickFileBasename file-picker-basename {})
(vim.api.nvim_create_user_command :PickBuffer buffer-picker {})
(vim.api.nvim_create_user_command :PickLspSymbols lsp-symbols-picker {})
(vim.api.nvim_create_user_command :PickLspWorkspaceSymbols
                                  lsp-workspace-symbols-picker {})

(vim.api.nvim_create_user_command :PickLspDiagnostics lsp-diagnostics-picker {})
(vim.api.nvim_create_user_command :PickLspReferences lsp-references-picker {})

(vim.keymap.set :n :<C-p> file-picker {:desc "Find files"})
(vim.keymap.set :n :<leader>fb buffer-picker {:desc "Find buffers"})
(vim.keymap.set :n :<leader>fs simple-file-picker {:desc "Find files (simple)"})
(vim.keymap.set :n :<leader>fn file-picker-basename {})
(vim.keymap.set :n :<leader>fo source-filter-picker {})
