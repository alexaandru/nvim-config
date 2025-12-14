(local picker (require :picker))
(local pikr picker.generic)
(local utils (require :picker.utils))
(local findfunc vim.g.findfunc)
(local (has-icons icons) (pcall require :mini.icons))

(fn get-file-icon [item]
  (if has-icons
      (let [{: get} icons]
        (get :file item.v))
      nil))

(fn open-with-cmd [open-cmd open-fn]
  (if open-cmd (vim.cmd open-cmd))
  (open-fn))

(fn is-binary-file [filepath]
  (let [file (io.open filepath "rb")]
    (if file
        (let [content (file:read 1024)]
          (file:close)
          (and content (content:find "\0")))
        false)))

(fn file-preview-item [filepath]
  (if (vim.fn.filereadable filepath)
      (if (is-binary-file filepath)
          (values (vim.fn.bufadd filepath) nil)
          (let [buf (vim.fn.bufadd filepath)]
            (vim.fn.bufload buf)
            (vim.api.nvim_set_option_value :filetype
                                           (or (vim.filetype.match {:filename filepath})
                                               "")
                                           {:buf buf})
            (values buf nil)))
      -1))

(fn open-file [filepath _ open-cmd]
  (when filepath
    (vim.schedule #(let [bufnr (vim.fn.bufnr filepath)]
                     (if (>= bufnr 0)
                         (vim.api.nvim_buf_delete bufnr {:force true}))
                     (open-with-cmd open-cmd
                                   #(do
                                      (vim.cmd (.. "edit " (vim.fn.fnameescape filepath)))
                                      (vim.cmd "normal! zx")))))))

(fn file-picker []
  (let [files (findfunc "" nil)]
    (picker.pick {:items files
                  :prompt :files
                  :fn picker.sorter
                  :on-close open-file
                  :get-icon get-file-icon
                  :preview-item file-preview-item
                  :actions {:setqflist (utils.make-setqflist (fn [item]
                                                               {:filename item.v}))}})))

(fn find-buffers []
  (-> (vim.iter (vim.api.nvim_list_bufs))
      (: :filter (fn [bufnr]
                   (and (vim.api.nvim_buf_is_valid bufnr)
                        (. vim.bo bufnr :buflisted))))
      (: :totable)))

(fn buffer-picker []
  (let [bufs (find-buffers)]
    (pikr bufs
          {:prompt :buffers
           :format-item (fn [bufnr]
                          (vim.api.nvim_buf_get_name bufnr))
           :on-close (fn [bufnr _ open-cmd]
                       (vim.schedule #(open-with-cmd open-cmd
                                                     #(vim.cmd.buffer bufnr))))
           :get-icon (fn [item]
                       (if has-icons
                           (let [{: get} icons]
                             (get :file (vim.api.nvim_buf_get_name item.v)))
                           nil))
           :preview-item (fn [bufnr] bufnr)
           :actions {:setqflist (utils.make-setqflist (fn [item]
                                                        {:bufnr item.v}))}})))

;; Recent files picker
(fn oldfiles-picker []
  (let [files (vim.tbl_filter (fn [f]
                                (and (vim.fn.filereadable f) (not= f "")))
                              (or vim.v.oldfiles []))]
    (pikr files
          {:prompt :oldfiles
           :on-close (fn [filepath _ open-cmd]
                       (vim.schedule #(open-with-cmd open-cmd
                                                     #(vim.cmd.edit filepath))))
           :get-icon get-file-icon
           :preview-item file-preview-item
           :actions {:setqflist (utils.make-setqflist (fn [item]
                                                        {:filename item.v}))}})))

;; Help tags picker
(fn help-picker []
  (let [tags (vim.fn.getcompletion "*" :help)
        items []]
    (each [_ tag (ipairs tags)]
      (table.insert items {:tag tag}))
    (pikr items
          {:prompt :help
           :format-item (fn [item] item.tag)
           :on-close (fn [item _]
                       (vim.schedule #(vim.cmd.help item.tag)))})))

;; Keymaps picker
(fn keymap-picker []
  (let [modes ["n" "i" "v" "x" "o" "c" "t"]
        items []]
    (each [_ mode (ipairs modes)]
      (let [maps (vim.api.nvim_get_keymap mode)]
        (each [_ map (ipairs maps)]
          (let [lhs map.lhs
                rhs (if map.callback
                        "<Lua function>"
                        (or map.rhs ""))
                desc (or map.desc "")
                mode-str (string.upper mode)]
            (table.insert items {:mode mode-str :lhs lhs :rhs rhs :desc desc})))))
    (pikr items {:prompt :keymaps
                 :format-item (fn [item] item.lhs)
                 :get-sign (fn [item]
                             (values item.v.mode
                                     (.. "PickerKeymap" item.v.mode)))
                 :get-virt-text (fn [item]
                                  (let [desc (if (not= item.v.desc "")
                                                 (.. item.v.desc " ")
                                                 "")
                                        rhs (if (not= item.v.rhs "")
                                                item.v.rhs
                                                "")]
                                    (when (not= (.. desc rhs) "")
                                      (.. desc rhs))))
                 :on-close (fn [_ _]
                             nil)})))

(fn lsp-symbols-picker []
  (if (not (next (vim.lsp.get_clients {:bufnr 0})))
      (vim.notify "No LSP client attached" vim.log.levels.WARN)
      (let [symbols []
            buf (vim.api.nvim_get_current_buf)
            params {:textDocument (vim.lsp.util.make_text_document_params)}
            results (vim.lsp.buf_request_sync 0 :textDocument/documentSymbol
                                              params 1000)]
        (each [_ result (pairs (or results {}))]
          (when result.result
            (fn flatten-symbols [syms prefix]
              (each [_ sym (ipairs syms)]
                (let [name (string.gsub (.. (or prefix "") sym.name) "\n" " ")
                      kind (. vim.lsp.protocol.SymbolKind sym.kind)
                      line (+ sym.range.start.line 1)]
                  (table.insert symbols
                                {:name name
                                 :kind kind
                                 :line line
                                 :range sym.range})
                  (if sym.children
                      (flatten-symbols sym.children (.. name "."))))))

            (flatten-symbols result.result)))
        (pikr symbols
              {:prompt "symbols"
               :format-item (fn [sym]
                              (string.format "%s [%s] :%d" sym.name sym.kind
                                             sym.line))
               :on-close (fn [sym _]
                           (vim.schedule #(do
                                            (vim.api.nvim_win_set_cursor 0
                                                                         [sym.line
                                                                          0])
                                            (vim.cmd "normal! zz"))))
               :preview-item (fn [sym]
                               (values buf
                                       (fn [win]
                                         (vim.api.nvim_set_option_value :cursorline
                                                                        true
                                                                        {:scope :local
                                                                         :win win})
                                         (vim.api.nvim_win_set_cursor win
                                                                      [sym.line
                                                                       0]))))}))))

;; LSP workspace symbols
(fn lsp-workspace-symbols-picker []
  (if (not (next (vim.lsp.get_clients {:bufnr 0})))
      (vim.notify "No LSP client attached" vim.log.levels.WARN)
      (picker.pick {:items []
                    :prompt "workspace symbols"
                    :fn picker.sorter
                    :get-items (fn [input]
                                 (if (< (length input) 2)
                                     []
                                     (let [symbols []
                                           params {:query input}
                                           results (vim.lsp.buf_request_sync 0
                                                                             "workspace/symbol"
                                                                             params
                                                                             2000)]
                                       (each [_ result (pairs (or results {}))]
                                         (when result.result
                                           (each [_ sym (ipairs result.result)]
                                             (let [name (string.gsub sym.name
                                                                     "\n" " ")
                                                   kind (. vim.lsp.protocol.SymbolKind
                                                           sym.kind)
                                                   file (vim.uri_to_fname sym.location.uri)
                                                   line (+ sym.location.range.start.line
                                                           1)]
                                               (table.insert symbols
                                                             {:id (+ (length symbols)
                                                                     1)
                                                              :v {:name name
                                                                  :kind kind
                                                                  :file file
                                                                  :line line}
                                                              :text (string.format "%s [%s] %s:%d"
                                                                                   name
                                                                                   kind
                                                                                   file
                                                                                   line)})))))
                                       symbols)))
                    :on-close (fn [sym _ open-cmd]
                                (vim.schedule #(open-with-cmd open-cmd
                                                              (fn []
                                                                (vim.cmd.edit sym.file)
                                                                (vim.api.nvim_win_set_cursor 0
                                                                                             [sym.line
                                                                                              0])
                                                                (vim.cmd "normal! zz")))))
                    :preview-item (fn [sym]
                                    (values (vim.fn.bufadd sym.file)
                                            (fn [win]
                                              (vim.api.nvim_set_option_value :cursorline
                                                                             true
                                                                             {:scope :local
                                                                              :win win})
                                              (vim.api.nvim_win_set_cursor win
                                                                           [sym.line
                                                                            0]))))})))

;; LSP diagnostics
(fn get-severity-hl [severity]
  (case severity
    1 "DiagnosticError"
    2 "DiagnosticWarn"
    3 "DiagnosticInfo"
    4 "DiagnosticHint"
    _ ""))

(fn lsp-diagnostics-picker []
  (let [diags (vim.diagnostic.get)]
    (if (= (length diags) 0)
        (vim.notify "No diagnostics found" vim.log.levels.INFO)
        (pikr diags
              {:prompt :diagnostics
               :format-item (fn [diag]
                              (let [text (string.gsub diag.message "\n" " ")]
                                (if diag.code
                                    (string.format "%d:%d :: %s [%s]"
                                                   (+ diag.lnum 1) diag.col text
                                                   diag.code)
                                    (string.format "%d:%d :: %s"
                                                   (+ diag.lnum 1) diag.col text))))
               :on-close (fn [diag _]
                           (vim.schedule #(let [win (vim.fn.bufwinid diag.bufnr)]
                                            (if (< win 0)
                                                (vim.api.nvim_win_set_buf 0
                                                                          diag.bufnr))
                                            (vim.api.nvim_win_set_cursor (if (>= win
                                                                                 0)
                                                                             win
                                                                             0)
                                                                         [(+ diag.lnum
                                                                             1)
                                                                          diag.col]))))
               :get-icon (fn [item]
                           (case item.v.severity
                             1 (values "E" (get-severity-hl 1))
                             2 (values "W" (get-severity-hl 2))
                             3 (values "I" (get-severity-hl 3))
                             4 (values "H" (get-severity-hl 4))
                             _ " "))
               :hl-item (fn [item]
                          [[[0 (length item.text)]
                            (get-severity-hl item.v.severity)]])
               :preview-item (fn [diag]
                               (values diag.bufnr
                                       (fn [win]
                                         (vim.api.nvim_set_option_value :cursorline
                                                                        true
                                                                        {:scope :local
                                                                         :win win})
                                         (vim.api.nvim_win_set_cursor win
                                                                      [(+ diag.lnum
                                                                          1)
                                                                       0]))))
               :actions {:setqflist (utils.make-setqflist (fn [item]
                                                            {:bufnr item.v.bufnr
                                                             :lnum (+ item.v.lnum
                                                                      1)
                                                             :col item.v.col
                                                             :text item.v.message}))}}))))

;; LSP references
(fn lsp-references-picker []
  (if (not (next (vim.lsp.get_clients {:bufnr 0})))
      (vim.notify "No LSP client attached" vim.log.levels.WARN)
      (let [refs []
            params (vim.lsp.util.make_position_params)
            _ (set params.context {:includeDeclaration true})
            results (vim.lsp.buf_request_sync 0 "textDocument/references"
                                              params 2000)]
        (each [_ result (pairs (or results {}))]
          (when result.result
            (each [_ ref (ipairs result.result)]
              (let [file (vim.uri_to_fname ref.uri)
                    line (+ ref.range.start.line 1)
                    col (+ ref.range.start.character 1)]
                (table.insert refs {:file file :line line :col col})))))
        (if (= (length refs) 0)
            (vim.notify "No references found" vim.log.levels.INFO)
            (pikr refs
                  {:prompt :references
                   :format-item (fn [ref]
                                  (string.format "%s:%d:%d" ref.file ref.line
                                                 ref.col))
                   :on-close (fn [ref _ open-cmd]
                               (vim.schedule #(open-with-cmd open-cmd
                                                             (fn []
                                                               (vim.cmd.edit ref.file)
                                                               (vim.api.nvim_win_set_cursor 0
                                                                                            [ref.line
                                                                                             (- ref.col
                                                                                                1)])
                                                               (vim.cmd "normal! zz")))))
                   :get-icon get-file-icon
                   :preview-item (fn [ref]
                                   (let [buf (file-preview-item ref.file)]
                                     (values buf
                                             (fn [win]
                                               (vim.api.nvim_set_option_value :cursorline
                                                                              true
                                                                              {:scope :local
                                                                               :win win})
                                               (vim.api.nvim_win_set_cursor win
                                                                            [ref.line
                                                                             0])))))
                   :actions {:setqflist (utils.make-setqflist (fn [item]
                                                                {:filename item.v.file
                                                                 :lnum item.v.line
                                                                 :col item.v.col}))}})))))

;; Live grep
(fn live-grep-picker []
  (picker.pick {:items []
                :prompt :grep
                :fn picker.sorter
                :get-items (fn [input]
                             (if (< (length input) 2)
                                 []
                                 (let [results []
                                       cmd (.. "rg --vimgrep --smart-case --max-count 500 "
                                               (vim.fn.shellescape input)
                                               " 2>/dev/null")
                                       output (vim.fn.system cmd)]
                                   (when (= vim.v.shell_error 0)
                                     (each [line (vim.gsplit output "\n")]
                                       (when (not= line "")
                                         (let [filepath (string.match line
                                                                      "^([^:]+):")
                                               lnum (tonumber (string.match line
                                                                            "^[^:]+:(%d+):"))
                                               col (tonumber (string.match line
                                                                           "^[^:]+:%d+:(%d+):"))
                                               text (string.match line
                                                                  "^[^:]+:%d+:%d+:(.*)$")]
                                           (when (and filepath lnum col text)
                                             (table.insert results
                                                           {:id (+ (length results)
                                                                   1)
                                                            :v {:file filepath
                                                                :line lnum
                                                                :col col}
                                                            :text text}))))))
                                   results)))
                :on-close (fn [item _ open-cmd]
                            (vim.schedule #(open-with-cmd open-cmd
                                                          (fn []
                                                            (vim.cmd.edit item.file)
                                                            (vim.api.nvim_win_set_cursor 0
                                                                                         [item.line
                                                                                          (- item.col
                                                                                             1)])
                                                            (vim.cmd "normal! zz")))))
                :get-icon (fn [item]
                            (if has-icons
                                (let [{: get} icons]
                                  (get :file item.v.file))
                                nil))
                :preview-item (fn [item]
                                (let [buf (file-preview-item item.file)]
                                  (values buf
                                          (fn [win]
                                            (vim.api.nvim_set_option_value :cursorline
                                                                           true
                                                                           {:scope :local
                                                                            :win win})
                                            (vim.api.nvim_win_set_cursor win
                                                                         [item.line
                                                                          0])))))
                :actions {:setqflist (utils.make-setqflist (fn [item]
                                                             {:filename item.v.file
                                                              :lnum item.v.line
                                                              :col item.v.col
                                                              :text item.text}))}}))

;; Commands picker
(fn command-picker []
  (let [cmds (vim.api.nvim_get_commands {})
        items []]
    (each [name info (pairs cmds)]
      (let [desc (or info.definition info.desc "")]
        (table.insert items {:name name :desc desc})))
    (table.sort items (fn [a b] (< a.name b.name)))
    (pikr items
          {:prompt :commands
           :format-item (fn [item] (string.format ":%s" item.name))
           :get-virt-text (fn [item]
                            (when (not= item.v.desc "")
                              item.v.desc))
           :on-close (fn [item _]
                       (vim.schedule #(vim.cmd (.. item.name))))})))

;; Git status picker
(fn git-status-picker []
  (let [output (vim.fn.system "git status --short 2>/dev/null")
        items []]
    (when (= vim.v.shell_error 0)
      (each [line (vim.gsplit output "\n")]
        (when (not= line "")
          (let [status (string.sub line 1 2)
                filepath (string.sub line 4)]
            (when (not= filepath "")
              (table.insert items
                            {:status status
                             :file filepath
                             :text (string.format "%s  %s" status filepath)})))))
      (pikr items
            {:prompt "git status"
             :format-item (fn [item] item.text)
             :on-close (fn [item _ open-cmd]
                         (vim.schedule #(open-with-cmd open-cmd
                                                       #(vim.cmd.edit item.file))))
             :get-icon (fn [item]
                         (if has-icons
                             (let [{: get} icons]
                               (get :file item.v.file))
                             nil))
             :preview-item (fn [item] (file-preview-item item.file))}))))

(fn colorscheme-picker []
  (let [original-cs (or vim.g.colors_name "default")
        files (vim.api.nvim_get_runtime_file "colors/*.{vim,lua}" true)
        colorschemes (vim.tbl_map (fn [f]
                                    (string.gsub (vim.fs.basename f) "%.[^.]+$"
                                                 ""))
                                  files)]
    (pikr colorschemes {:prompt :colorschemes
                        :on-close (fn [cs _]
                                    (vim.schedule #(vim.cmd.colorscheme cs)))
                        :on-cancel (fn []
                                     (vim.schedule #(pcall vim.cmd.colorscheme
                                                           original-cs)))
                        :preview-item (fn [cs]
                                        (pcall vim.cmd.colorscheme cs)
                                        -1)})))

;; Create commands
(let [com #(vim.api.nvim_create_user_command $ $2 {:desc $3})]
  (com :PickFile file-picker "Files picker")
  (com :PickBuffer buffer-picker "Buffers picker")
  (com :PickOldfiles oldfiles-picker "Recent files picker")
  (com :PickHelp help-picker "Help tags picker")
  (com :PickKeymap keymap-picker "Keymaps picker")
  (com :PickLspSymbols lsp-symbols-picker "LSP document symbols picker")
  (com :PickLspWorkspaceSymbols lsp-workspace-symbols-picker
       "LSP workspace symbols picker")
  (com :PickLspDiagnostics lsp-diagnostics-picker "LSP diagnostics picker")
  (com :PickLspReferences lsp-references-picker "LSP references picker")
  (com :LiveGrep live-grep-picker "Live grep with ripgrep")
  (com :PickColorscheme colorscheme-picker
       "Colorscheme picker with live preview")
  (com :PickCommand command-picker "Commands picker")
  (com :PickGitStatus git-status-picker "Git status picker"))

;; LSP keymaps on attach
(vim.api.nvim_create_autocmd :LspAttach
                             {:callback (fn [ev]
                                          (let [opts {:buffer ev.buf
                                                      :silent true}
                                                nmap #(vim.keymap.set :n $1 $2
                                                                      opts)]
                                            (nmap :<leader>ls
                                                  lsp-symbols-picker)
                                            (nmap :<leader>lw
                                                  lsp-workspace-symbols-picker)
                                            (nmap :<leader>ld
                                                  lsp-diagnostics-picker)
                                            (nmap :<leader>lr
                                                  lsp-references-picker)))})

(let [nmap #(vim.keymap.set :n $1 $2 {:desc $3})]
  (nmap :<C-p> file-picker "Find files")
  (nmap :<C-b> buffer-picker "Find buffers")
  (nmap "<C-;>" live-grep-picker "Live grep")
  (nmap :<leader>lc colorscheme-picker "Pick colorscheme"))
