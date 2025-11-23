(local picker (require :picker))
(local findfunc vim.g.findfunc)
(local (has-devicons devicons) (pcall require :nvim-web-devicons))
(local {: get_icon} devicons)

(fn set-file-icons [buf lines]
  (if has-devicons
      (let [ns (vim.api.nvim_create_namespace :file-picker-icons)]
        ;; Clear existing extmarks first
        (vim.api.nvim_buf_clear_namespace buf ns 0 -1)
        (each [i line (ipairs lines)]
          (if (and line (not= line ""))
              (let [(icon color) (get_icon (vim.fn.fnamemodify line ":t"))
                    (fallback-icon fallback-color) (get_icon "default.txt")
                    final-icon (or icon fallback-icon)
                    final-color (or color fallback-color "Normal")
                    extmark vim.api.nvim_buf_set_extmark]
                (extmark buf ns (- i 1) 0
                         {:virt_text [[(.. " " final-icon " ") final-color]]
                          :virt_text_pos :inline})))))))

(fn is-binary-file [filepath]
  (let [file (io.open filepath "rb")]
    (if file
        (let [content (file:read 1024)] ; Read first 1024 bytes
          (file:close)
          (and content (content:find "\0")))
        false)))

(fn file-preview [filename _]
  (if (vim.fn.filereadable filename)
      (if (is-binary-file filename)
          {:content ["[Binary file]"] : filename}
          (let [lines (vim.fn.readfile filename)]
            (if (> (length lines) 0)
                {:content lines : filename}
                {:content ["[Empty file]"] : filename})))
      {:content ["[File not readable]"] : filename}))

(fn open-file [filepath _ original-win]
  (when filepath
    (if (vim.api.nvim_win_is_valid original-win)
        (vim.api.nvim_set_current_win original-win))
    (vim.cmd.edit filepath)))

(fn open-multiple-files [filepaths original-win]
  (when (> (length filepaths) 0)
    (if (vim.api.nvim_win_is_valid original-win)
        (vim.api.nvim_set_current_win original-win))
    (each [_ filepath (ipairs filepaths)]
      (vim.cmd.edit filepath))
    (vim.notify (.. "Opened " (length filepaths) " files") vim.log.levels.INFO)))

(fn file-picker []
  (picker (fn [filter _]
            (findfunc filter _))
          {:preview-fn file-preview
           :on-select open-file
           :on-multi-select open-multiple-files
           :setup-list-fn set-file-icons
           :config {:prompt "Find File: " :preview {:width-ratio 0.55}}}))

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
        (vim.fn.matchfuzzy buffers filter))))

(fn buffer-preview [bufname _]
  (let [all-bufs (vim.api.nvim_list_bufs)]
    (var target-buf nil)
    (var target-name nil)
    (each [_ buf (ipairs all-bufs)]
      (if (vim.api.nvim_buf_is_loaded buf)
          (let [name (vim.api.nvim_buf_get_name buf)
                display-name (if (= name "") "[No Name]"
                                 (vim.fn.fnamemodify name ":t"))]
            (if (= display-name bufname)
                (do
                  (set target-buf buf)
                  (set target-name name))))))
    (if target-buf
        {:content (vim.api.nvim_buf_get_lines target-buf 0 30 false)
         :filename target-name}
        {:content ["[Buffer not found]"]})))

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
           :setup-list-fn set-file-icons
           :config {:prompt "Switch Buffer: "}}))

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
        (vim.fn.matchfuzzy symbols filter))))

(fn lsp-symbols-preview [item _]
  (let [line-match (string.match item ":(%d+)$")]
    (if line-match
        (let [line-num (tonumber line-match)
              current-buf (vim.api.nvim_get_current_buf)
              current-file (vim.api.nvim_buf_get_name current-buf)
              lines (vim.api.nvim_buf_get_lines current-buf
                                                (math.max 0 (- line-num 5))
                                                (+ line-num 10) false)]
          {:content lines :filename current-file :line line-num})
        {:content ["[Could not parse symbol location]"]})))

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
               :config {:prompt "LSP Symbols: " :width 120 :height 30}})
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

(fn lsp-workspace-symbols-preview [item _]
  (let [file-match (string.match item " ([^:]+):(%d+)$")]
    (if file-match
        (let [filepath (string.match item " ([^:]+):%d+$")
              line-num (tonumber (string.match item ":(%d+)$"))]
          (if (vim.fn.filereadable filepath)
              (let [lines (vim.fn.readfile filepath (+ line-num 10)
                                           (math.max 1 (- line-num 5)))]
                (if (> (length lines) 0)
                    {:content lines :filename filepath :line line-num}
                    {:content ["[Empty file]"] :filename filepath}))
              {:content ["[File not readable]"] :filename filepath}))
        {:content ["[Could not parse location]"]})))

(fn lsp-workspace-symbols-select [item _ original-win]
  (let [filepath (string.match item " ([^:]+):%d+$")
        line-num (tonumber (string.match item ":(%d+)$"))]
    (when (and filepath line-num)
      (if (vim.api.nvim_win_is_valid original-win)
          (vim.api.nvim_set_current_win original-win))
      (vim.cmd.edit filepath)
      (vim.api.nvim_win_set_cursor 0 [line-num 0])
      (vim.cmd "normal! zz"))))

(fn lsp-workspace-symbols-picker []
  (if (next (vim.lsp.get_clients {:bufnr 0}))
      (picker lsp-workspace-symbols-source
              {:preview-fn lsp-workspace-symbols-preview
               :on-select lsp-workspace-symbols-select
               :config {:prompt "Workspace Symbols: " :width 140 :height 35}})
      (vim.notify "No LSP client attached" vim.log.levels.WARN)))

(var diagnostics-data [])

(fn lsp-diagnostics-source [filter _]
  (let [diagnostics []
        diag-list (vim.diagnostic.get)]
    (set diagnostics-data [])
    (each [_ diag (ipairs diag-list)]
      (let [file (vim.api.nvim_buf_get_name diag.bufnr)
            line (+ diag.lnum 1)
            message (string.gsub diag.message "\n" " ")
            item {:message message :file file :line line :diagnostic diag}]
        (table.insert diagnostics message)
        (table.insert diagnostics-data item)))
    (if (= (length filter) 0)
        diagnostics
        ;; When filtering, maintain correspondence between filtered items and their data
        (let [filtered (vim.fn.matchfuzzy diagnostics filter)
              filtered-data []]
          (each [_ filtered-msg (ipairs filtered)]
            (each [_ item (ipairs diagnostics-data)]
              (if (= item.message filtered-msg)
                  (table.insert filtered-data item))))
          (set diagnostics-data filtered-data)
          filtered))))

(fn lsp-diagnostics-preview [_ idx]
  (let [data-item (. diagnostics-data idx)]
    (if (and data-item data-item.file (vim.fn.filereadable data-item.file))
        (let [lines (vim.fn.readfile data-item.file)]
          (if (and (> (length lines) 0) (<= data-item.line (length lines)))
              ;; Return entire file content with diagnostic info for highlighting
              {:content lines
               :filename data-item.file
               :line data-item.line
               :diagnostic data-item.diagnostic}
              {:content ["[Line out of range]"] :filename data-item.file}))
        {:content ["[File not readable]"] :filename (or data-item.file "")})))

(fn lsp-diagnostics-select [_ idx original-win]
  (let [data-item (. diagnostics-data idx)]
    (when (and data-item data-item.file data-item.line)
      (if (vim.api.nvim_win_is_valid original-win)
          (vim.api.nvim_set_current_win original-win))
      (vim.cmd.edit data-item.file)
      (vim.api.nvim_win_set_cursor 0 [data-item.line 0])
      (vim.cmd "normal! zz"))))

(fn lsp-diagnostics-multi-select [items original-win]
  (let [qf-list []]
    (each [_ message (ipairs items)]
      (each [_ data-item (ipairs diagnostics-data)]
        (when (= data-item.message message)
          (table.insert qf-list
                        {:filename data-item.file
                         :lnum data-item.line
                         :col (or data-item.diagnostic.col 0)
                         :text data-item.message
                         :type (case data-item.diagnostic.severity
                                 1 "E"
                                 2 "W"
                                 3 "I"
                                 4 "H"
                                 _  "E")}))))
    (vim.fn.setqflist qf-list)
    (if (vim.api.nvim_win_is_valid original-win)
        (vim.api.nvim_set_current_win original-win))
    (vim.cmd.copen)
    (vim.notify (.. "Added " (length qf-list) " diagnostics to quickfix")
                vim.log.levels.INFO)))

(fn setup-diagnostics-signs [buf lines]
  (let [ns (vim.api.nvim_create_namespace :diagnostics-picker-signs)
        ;; Use unicode emoji signs if available, otherwise fallback to letters
        severity-to-sign (if has-devicons
                             {1 "✘" 2 "⚠" 3 "i" 4 "h"}
                             {1 "E" 2 "W" 3 "I" 4 "H"})
        severity-to-hl {1 "DiagnosticSignError"
                        2 "DiagnosticSignWarn"
                        3 "DiagnosticSignInfo"
                        4 "DiagnosticSignHint"}]
    ;; Enable word wrap for long diagnostic messages
    (let [win (vim.fn.bufwinid buf)]
      (when (> win -1)
        (vim.api.nvim_set_option_value :wrap true {:win win})
        (vim.api.nvim_set_option_value :linebreak true {:win win})))
    (vim.api.nvim_buf_clear_namespace buf ns 0 -1)
    (each [i line (ipairs lines)]
      (when line
        (let [data-item (. diagnostics-data i)]
          (when data-item
            (let [sign (or (. severity-to-sign data-item.diagnostic.severity)
                           "?")
                  hl (or (. severity-to-hl data-item.diagnostic.severity)
                         "Normal")]
              (vim.api.nvim_buf_set_extmark buf ns (- i 1) 0
                                            {:sign_text sign :sign_hl_group hl}))))))))

(fn lsp-diagnostics-picker []
  (let [diag-count (length (vim.diagnostic.get))]
    (if (> diag-count 0)
        (picker lsp-diagnostics-source
                {:preview-fn lsp-diagnostics-preview
                 :on-select lsp-diagnostics-select
                 :on-multi-select lsp-diagnostics-multi-select
                 :setup-list-fn setup-diagnostics-signs
                 :config {:prompt "Diagnostics: " :width 140 :height 30}})
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
        (vim.fn.matchfuzzy references filter))))

(fn lsp-references-preview [item _]
  (let [filepath (string.match item "^([^:]+):")
        line-num (tonumber (string.match item ":(%d+):"))]
    (if (and filepath line-num (vim.fn.filereadable filepath))
        (let [lines (vim.fn.readfile filepath)]
          (if (and (> (length lines) 0) (<= line-num (length lines)))
              {:content (vim.list_slice lines (math.max 1 (- line-num 3))
                                        (math.min (length lines) (+ line-num 3)))
               :filename filepath
               :line line-num}
              {:content ["[Line out of range]"] :filename filepath}))
        {:content ["[File not readable]"] :filename filepath})))

(fn lsp-references-select [item _ original-win]
  (let [filepath (string.match item "^([^:]+):")
        line-num (tonumber (string.match item ":(%d+):"))
        col-num (tonumber (string.match item ":(%d+)$"))]
    (when (and filepath line-num col-num)
      (if (vim.api.nvim_win_is_valid original-win)
          (vim.api.nvim_set_current_win original-win))
      (vim.cmd.edit filepath)
      (vim.api.nvim_win_set_cursor 0 [line-num col-num])
      (vim.cmd "normal! zz"))))

(fn lsp-references-picker []
  (if (next (vim.lsp.get_clients {:bufnr 0}))
      (picker lsp-references-source
              {:preview-fn lsp-references-preview
               :on-select lsp-references-select
               :config {:prompt "References: " :width 140 :height 35}})
      (vim.notify "No LSP client attached" vim.log.levels.WARN)))

;; Live grep implementation
(var grep-data [])
(var grep-query "")

(fn live-grep-source [filter _]
  (set grep-data [])
  (set grep-query filter)
  (if (< (length filter) 2)
      []
      (let [results []
            cmd (.. "rg --vimgrep --smart-case --max-count 1000 "
                    (vim.fn.shellescape filter) " 2>/dev/null")
            output (vim.fn.system cmd)]
        (when (= vim.v.shell_error 0)
          (each [line (vim.gsplit output "\n")]
            (when (not= line "")
              (let [filepath (string.match line "^([^:]+):")
                    line-num (tonumber (string.match line "^[^:]+:(%d+):"))
                    col-num (tonumber (string.match line "^[^:]+:%d+:(%d+):"))
                    text (string.match line "^[^:]+:%d+:%d+:(.*)$")]
                (when (and filepath line-num col-num text)
                  (let [display (.. filepath ":" line-num)
                        item {:filepath filepath
                              :line line-num
                              :col col-num
                              :text text}]
                    (table.insert results display)
                    (table.insert grep-data item)))))))
        results)))

(fn live-grep-preview [_ idx]
  (let [data-item (. grep-data idx)]
    (if (and data-item data-item.filepath
             (vim.fn.filereadable data-item.filepath))
        (let [lines (vim.fn.readfile data-item.filepath)]
          (if (and (> (length lines) 0) (<= data-item.line (length lines)))
              {:content lines
               :filename data-item.filepath
               :line data-item.line
               :search-pattern grep-query}
              {:content ["[Line out of range]"] :filename data-item.filepath}))
        {:content ["[File not readable]"]
         :filename (or (and data-item data-item.filepath) "")})))

(fn live-grep-select [_ idx original-win]
  (let [data-item (. grep-data idx)]
    (when (and data-item data-item.filepath data-item.line)
      (if (vim.api.nvim_win_is_valid original-win)
          (vim.api.nvim_set_current_win original-win))
      (vim.cmd.edit data-item.filepath)
      (vim.api.nvim_win_set_cursor 0 [data-item.line (- data-item.col 1)])
      (vim.cmd "normal! zz"))))

(fn live-grep-picker []
  (picker live-grep-source {:preview-fn live-grep-preview
                            :on-select live-grep-select
                            :setup-list-fn set-file-icons
                            :dynamic-source true
                            :config {:prompt "Live Grep: "
                                     :width 140
                                     :height 35}}))

;; fnlfmt: skip
(vim.api.nvim_create_autocmd :LspAttach
     {:callback #(let [bufnr $.buf
                       opts {:buffer bufnr :silent true}
                       nmap #(vim.keymap.set :n $1 $2 $3)]
                   (nmap :<leader>ls lsp-symbols-picker opts)
                   (nmap :<leader>lw lsp-workspace-symbols-picker opts)
                   (nmap :<leader>ld lsp-diagnostics-picker opts)
                   (nmap :<leader>lr lsp-references-picker opts))})

(let [com vim.api.nvim_create_user_command]
  (com :PickFile file-picker {:desc "Files picker"})
  (com :PickBuffer buffer-picker {:desc "Buffers picker"})
  (com :PickLspSymbols lsp-symbols-picker {:desc "LSP document symbols picker"})
  (com :PickLspWorkspaceSymbols lsp-workspace-symbols-picker
       {:desc "LSP workspace symbols picker"})
  (com :PickLspDiagnostics lsp-diagnostics-picker
       {:desc "LSP diagnostics picker"})
  (com :PickLspReferences lsp-references-picker {:desc "LSP references picker"})
  (com :LiveGrep live-grep-picker {:desc "Live grep with ripgrep"}))

(let [nmap #(vim.keymap.set :n $1 $2 $3)]
  (nmap :<C-p> file-picker {:desc "Find files"})
  (nmap :<C-b> buffer-picker {:desc "Find buffers"})
  (nmap "<C-;>" live-grep-picker {:desc "Live grep"}))
