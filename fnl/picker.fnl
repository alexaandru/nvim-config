(local {: float-win} (require :util))

;; fnlfmt: skip
(local default-config {:preview {:width-ratio 0.5 :number false}
                       :keymaps {:close [:<Esc> :<C-c>]
                                 :select [:<CR> :<Tab>]
                                 :preview-toggle [:<C-p>]
                                 :scroll-preview-up [:<C-u>]
                                 :scroll-preview-down [:<C-d>]}
                       :prompt "Select: "})

(fn create-picker-state []
  {:filter-buf nil
   :filter-close nil
   :list-buf nil
   :list-close nil
   :preview-buf nil
   :preview-close nil
   :items []
   :filtered-items []
   :selected-idx 1
   :filter-text ""
   :all-items []
   :preview-fn nil
   :on-select nil
   :on-multi-select nil
   :source-fn nil
   :setup-list-fn nil
   :config {}
   :original-win nil
   :dynamic-source false
   :selected-items {}})

(local o vim.api.nvim_set_option_value)
(local c vim.api.nvim_win_set_config)

;; fnlfmt: skip
(fn calculate-layout [config preview-enabled]
  (let [total-width (math.floor (* 0.8 vim.o.columns))
        total-height (math.floor (* 0.8 vim.o.lines))
        preview-width (if preview-enabled (math.floor (* total-width config.preview.width-ratio)) 0)
        list-width (- total-width preview-width)
        filter-height 1
        list-height (- total-height filter-height 1)
        start-row (math.floor (/ (- vim.o.lines total-height) 2))
        start-col (math.floor (/ (- vim.o.columns total-width) 2))]
    {:filter {:width list-width :height filter-height :row start-row :col start-col}
     :list {:width list-width :height list-height :row (+ start-row filter-height 1) :col start-col}
     :preview (if preview-enabled {:width preview-width :height total-height :row start-row :col (+ start-col list-width 1)})}))

(fn update-filter [state filter-text]
  (set state.filter-text filter-text)
  ;; If source-fn is dynamic (re-calls on filter change), use it
  ;; Otherwise do local fuzzy matching
  (if state.dynamic-source
      (let [new-items (state.source-fn filter-text nil)]
        (set state.all-items new-items)
        (set state.filtered-items new-items))
      (if (= (length filter-text) 0)
          (set state.filtered-items state.all-items)
          (let [strict-mode (string.find filter-text "^'")
                search-text (if strict-mode (string.sub filter-text 2)
                                filter-text)]
            (set state.filtered-items
                 (if strict-mode
                     (vim.fn.filter state.all-items #($2:find search-text))
                     (vim.fn.matchfuzzy state.all-items search-text))))))
  (set state.selected-idx 1)
  ;; Clear multi-selection when filter changes
  (set state.selected-items {}))

(fn update-list-display [state]
  (let [buf state.list-buf
        items state.filtered-items]
    (when buf
      (o :modifiable true {: buf})
      (vim.api.nvim_buf_set_lines buf 0 -1 false items)
      (if state.setup-list-fn
          (state.setup-list-fn buf items))
      (o :modifiable false {: buf})
      (o :modified false {: buf})
      ;; Update multi-selection markers
      (vim.fn.sign_unplace "picker-selected" {:buffer buf})
      (each [idx _ (pairs state.selected-items)]
        (when (and (>= idx 1) (<= idx (length items)))
          (vim.fn.sign_place 0 "picker-selected" "PickerSelected" buf
                             {:lnum idx :priority 100})))
      (let [list-win (vim.fn.bufwinid buf)]
        (if (> list-win -1)
            (let [total-items (length items)
                  idx state.selected-idx
                  selected-count (length (vim.tbl_keys state.selected-items))
                  title (if (> selected-count 0)
                            (.. " Results " idx "/" total-items " (" selected-count " selected) ")
                            (.. " Results " idx "/" total-items " "))]
              (c list-win {: title :title_pos :center})
              (vim.api.nvim_win_set_cursor list-win [idx 0])))))))

(fn update-preview [state]
  (if (and state.preview-buf state.preview-fn
           (> (length state.filtered-items) 0))
      (let [current-item (. state.filtered-items state.selected-idx)]
        (if current-item
            (let [preview-content (state.preview-fn current-item
                                                    state.selected-idx)]
              (o :modifiable true {:buf state.preview-buf})
              ;; All preview functions now return enhanced format
              (vim.api.nvim_buf_set_lines state.preview-buf 0 -1 false
                                          preview-content.content)
              ;; Set filetype based on filename if available
              (when preview-content.filename
                (let [filetype (vim.filetype.match {:filename preview-content.filename})]
                  (when filetype
                    (o :filetype filetype {:buf state.preview-buf})
                    (pcall #(vim.treesitter.start state.preview-buf filetype)))))
              ;; Position cursor on specific line if provided
              (when preview-content.line
                (let [preview-win (vim.fn.bufwinid state.preview-buf)]
                  (when (> preview-win -1)
                    (vim.api.nvim_win_set_cursor preview-win
                                                 [preview-content.line 0])
                    (vim.api.nvim_win_call preview-win #(vim.cmd "normal! zz")))))
              ;; Set search pattern for highlighting if provided
              (when preview-content.search-pattern
                (let [preview-win (vim.fn.bufwinid state.preview-buf)]
                  (when (> preview-win -1)
                    (vim.api.nvim_win_call preview-win
                                           #(do
                                              (vim.fn.setreg "/"
                                                             preview-content.search-pattern)
                                              (set vim.o.hlsearch true))))))
              ;; Apply diagnostic highlights if diagnostic info is provided
              (when preview-content.diagnostic
                (let [diag preview-content.diagnostic
                      ns (vim.api.nvim_create_namespace "diagnostics-picker-preview")
                      severity-to-hl {1 "DiagnosticUnderlineError"
                                      2 "DiagnosticUnderlineWarn"
                                      3 "DiagnosticUnderlineInfo"
                                      4 "DiagnosticUnderlineHint"}
                      severity-to-line-hl {1 "DiagnosticVirtualTextError"
                                           2 "DiagnosticVirtualTextWarn"
                                           3 "DiagnosticVirtualTextInfo"
                                           4 "DiagnosticVirtualTextHint"}
                      line-hl (or (. severity-to-line-hl diag.severity)
                                  "DiagnosticVirtualTextError")
                      underline-hl (or (. severity-to-hl diag.severity)
                                       "DiagnosticUnderlineError")]
                  (vim.api.nvim_buf_clear_namespace state.preview-buf ns 0 -1)
                  ;; Highlight the entire line with a subtle background
                  (vim.api.nvim_buf_set_extmark state.preview-buf ns diag.lnum
                                                0
                                                {:end_line (+ diag.lnum 1)
                                                 :hl_group line-hl
                                                 :priority 50})
                  ;; Apply diagnostic underline to the specific range
                  (when (and diag.col (>= diag.col 0))
                    (let [end-col (or diag.end_col (+ diag.col 1))]
                      (vim.api.nvim_buf_set_extmark state.preview-buf ns
                                                    diag.lnum diag.col
                                                    {:end_col end-col
                                                     :hl_group underline-hl
                                                     :priority 100})))))
              (o :modifiable false {:buf state.preview-buf})
              (o :modified false {:buf state.preview-buf}))
            ;; Update preview window title with footer info
            (if state.preview-fn
                (let [preview-win (vim.fn.bufwinid state.preview-buf)]
                  (if (> preview-win -1)
                      (let [cursor (vim.api.nvim_win_get_cursor preview-win)
                            line (. cursor 1)
                            total-lines (vim.api.nvim_buf_line_count state.preview-buf)
                            percentage (if (> total-lines 0)
                                           (math.floor (* (/ line total-lines)
                                                          100))
                                           0)
                            title (.. " Preview " percentage "% ")]
                        (c preview-win {:title title :title_pos :center})))))))))

(fn move-selection [state direction]
  (let [max-idx (length state.filtered-items)]
    (when (> max-idx 0)
      (set state.selected-idx
           (case direction
             :up (math.max 1 (- state.selected-idx 1))
             :down (math.min max-idx (+ state.selected-idx 1))))
      (update-list-display state)
      (update-preview state))))

(fn move-selection-page [state direction]
  (let [max-idx (length state.filtered-items)
        list-win (vim.fn.bufwinid state.list-buf)]
    (when (and (> max-idx 0) (> list-win -1))
      (let [win-height (vim.api.nvim_win_get_height list-win)
            page-size (math.max 1 (- win-height 1))]
        (set state.selected-idx
             (case direction
               :up (math.max 1 (- state.selected-idx page-size))
               :down (math.min max-idx (+ state.selected-idx page-size))))
        (update-list-display state)
        (update-preview state)))))

(fn toggle-selection [state select?]
  (let [idx state.selected-idx]
    (when (and (> (length state.filtered-items) 0) (<= idx (length state.filtered-items)))
      (if select?
          (tset state.selected-items idx true)
          (tset state.selected-items idx nil))
      (update-list-display state))))

;; fnlfmt: skip
(fn close-picker [state]
    (vim.schedule (fn []
                    (each [_ close-fn (pairs [state.filter-close state.list-close state.preview-close])]
                      (if (and close-fn (= (type close-fn) :function)) (pcall close-fn)))
                    (each [_ key (ipairs [:filter-buf :filter-close :list-buf :list-close :preview-buf :preview-close])]
                      (tset state key nil))
                    (set state.all-items []))))

(fn select-current [state]
  (if (> (length state.filtered-items) 0)
      (let [selected-count (length (vim.tbl_keys state.selected-items))]
        (if (and (> selected-count 0) state.on-multi-select)
            ;; Multi-selection mode: gather all selected items
            (let [selected-items []
                  on-multi-select-fn state.on-multi-select]
              (each [idx _ (pairs state.selected-items)]
                (table.insert selected-items (. state.filtered-items idx)))
              (close-picker state)
              (vim.schedule #(on-multi-select-fn selected-items state.original-win)))
            ;; Single selection mode: use current item
            (when state.on-select
              (let [selected-item (. state.filtered-items state.selected-idx)
                    on-select-fn state.on-select]
                (close-picker state)
                (vim.schedule #(on-select-fn selected-item state.selected-idx
                                             state.original-win))))))))

;; fnlfmt: skip
(fn setup-filter-window [state buf]
    (o :buftype :prompt {: buf})
    (vim.api.nvim_buf_call buf #(vim.cmd "setl nobl bt=prompt bh=delete noswf"))
    (vim.api.nvim_create_autocmd [:TextChanged :TextChangedI]
                                 {:buffer buf
                                  :callback #(let [lines (vim.api.nvim_buf_get_lines buf 0 -1 false)
                                                   filter-text (or (and (> (length lines) 0) (string.sub (. lines 1) 3)) "")]
                                               (update-filter state filter-text)
                                               (update-list-display state)
                                               (update-preview state)
                                               ;; Reset modified state to prevent E37
                                               (vim.api.nvim_set_option_value :modified false {: buf}))}))

(fn setup-list-window [state buf]
  (vim.api.nvim_buf_call buf #(vim.cmd "Scratchify"))
  (let [win (vim.fn.bufwinid buf)]
    (when (> win -1)
      (o :cursorline true {: win})
      (o :signcolumn "auto:2" {: win})
      (o :winhighlight
         "Normal:Normal,CursorLine:PmenuSel,FloatBorder:Normal,Cursor:CursorLine"
         {: win})))
  ;; Define sign for selected items with orange color
  (vim.api.nvim_set_hl 0 "PickerSelectedSign" {:fg "#ff8800" :bold true})
  (vim.fn.sign_define "PickerSelected" {:text "▐" :texthl "PickerSelectedSign"})
  ;; Add autocmd to track cursor movements (including mouse clicks) and update selection
  (vim.api.nvim_create_autocmd :CursorMoved
                               {:buffer buf
                                :callback #(let [win (vim.fn.bufwinid buf)]
                                             (when (> win -1)
                                               (let [cursor (vim.api.nvim_win_get_cursor win)
                                                     line (. cursor 1)]
                                                 (when (and (<= line
                                                                (length state.filtered-items))
                                                            (not= line
                                                                  state.selected-idx))
                                                   (set state.selected-idx line)
                                                   (update-preview state)))))}))

(fn setup-preview-window [buf config]
  (vim.api.nvim_buf_call buf #(vim.cmd "Scratchify"))
  (let [win (vim.fn.bufwinid buf)]
    (when (> win -1)
      (o :wrap false {: win})
      (o :number config.preview.number {: win})
      (o :cursorline false {: win})
      (o :winhighlight "Normal:Normal,FloatBorder:Normal" {: win})
      (o :foldenable false {: win})
      (o :syntax :enable {: buf}))))

(fn setup-keymaps [state _config close-keys select-keys]
  (let [filter-opts {:buffer state.filter-buf :silent true}
        list-opts {:buffer state.list-buf :silent true}
        imap #(vim.keymap.set :i $1 $2 filter-opts)
        nmap #(vim.keymap.set :n $1 $2 list-opts)]
    (each [_ key (ipairs close-keys)]
      (imap key #(close-picker state)))
    (each [_ key (ipairs select-keys)]
      (imap key #(select-current state)))
    (imap :<Up> #(move-selection state :up))
    (imap :<Down> #(move-selection state :down))
    (imap :<C-n> #(move-selection state :down))
    (imap :<C-p> #(move-selection state :up))
    (imap :<PageUp> #(move-selection-page state :up))
    (imap :<PageDown> #(move-selection-page state :down))
    (imap :<C-u> #(move-selection-page state :up))
    (imap :<C-d> #(move-selection-page state :down))
    (imap :<Right> #(do
                      (toggle-selection state true)
                      (move-selection state :down)))
    (imap :<Left> #(do
                     (toggle-selection state false)
                     (move-selection state :up)))
    (imap "'" "'")
    (imap :<M-k>
          #(if state.preview-buf
               (let [preview-win (vim.fn.bufwinid state.preview-buf)]
                 (if (> preview-win -1)
                     (vim.fn.win_execute preview-win "normal! 5k")))))
    (imap :<M-j>
          #(if state.preview-buf
               (let [preview-win (vim.fn.bufwinid state.preview-buf)]
                 (if (> preview-win -1)
                     (vim.fn.win_execute preview-win "normal! 5j")))))
    (each [_ key (ipairs close-keys)]
      (nmap key #(close-picker state)))
    (each [_ key (ipairs select-keys)]
      (nmap key #(select-current state)))
    (nmap :j #(move-selection state :down))
    (nmap :k #(move-selection state :up))
    (nmap :<Down> #(move-selection state :down))
    (nmap :<Up> #(move-selection state :up))
    (nmap :<PageUp> #(move-selection-page state :up))
    (nmap :<PageDown> #(move-selection-page state :down))
    (nmap :<C-u> #(move-selection-page state :up))
    (nmap :<C-d> #(move-selection-page state :down))
    (nmap :<Right> #(do
                      (toggle-selection state true)
                      (move-selection state :down)))
    (nmap :<Left> #(do
                     (toggle-selection state false)
                     (move-selection state :up)))
    (nmap :x #(let [idx state.selected-idx]
               (toggle-selection state (not (. state.selected-items idx)))))
    ;; Redirect typing to filter buffer (excluding 'x' which is used for toggle)
    (let [chars "abcdefghijklmnopqrstuvwyzABCDEFGHIJKLMNOPQRSTUVWYZ0123456789-_./:'\"[]{}()<>!@#$%^&*+=~`|\\;,?"]
      (for [i 1 (length chars)]
        (let [char (string.sub chars i i)]
          (nmap char
                #(let [filter-win (vim.fn.bufwinid state.filter-buf)]
                   (when (> filter-win -1)
                     (vim.api.nvim_set_current_win filter-win)
                     (vim.api.nvim_feedkeys char :n false)))))))
    (if state.preview-buf
        (let [preview-opts {:buffer state.preview-buf :silent true}
              preview-nmap #(vim.keymap.set :n $1 $2 preview-opts)]
          (each [_ key (ipairs close-keys)]
            (preview-nmap key #(close-picker state)))
          (each [_ key (ipairs select-keys)]
            (preview-nmap key #(select-current state)))
          (preview-nmap ":"
                        #(let [filter-win (vim.fn.bufwinid state.filter-buf)]
                           (when (> filter-win -1)
                             (vim.api.nvim_set_current_win filter-win)
                             (vim.cmd.startinsert))))))))

(fn [source-fn opts]
  (vim.validate {:source-fn [source-fn :function]})
  (let [state (create-picker-state)
        config (vim.tbl_deep_extend :force default-config (or opts.config {}))
        close-keys config.keymaps.close
        select-keys config.keymaps.select
        preview-enabled (not= opts.preview-fn nil)]
    ;; Initialize state
    (set state.original-win (vim.api.nvim_get_current_win))
    (set state.source-fn source-fn)
    (set state.preview-fn opts.preview-fn)
    (set state.on-select opts.on-select)
    (set state.on-multi-select opts.on-multi-select)
    (set state.setup-list-fn opts.setup-list-fn)
    (set state.config config)
    (set state.dynamic-source (or opts.dynamic-source false))
    ;; Get initial items
    (set state.items (source-fn "" nil))
    (set state.all-items state.items)
    (set state.filtered-items state.items)
    (set state.selected-idx 1)
    (set state.filter-text "")
    ;; Calculate layout
    (let [layout (calculate-layout config preview-enabled)]
      ;; Create filter window using float-win with custom border
      (let [filter-border ["╭" "─" "┬" "│" "┤" "─" "├" "│"]
            (filter-buf filter-close) (float-win [""] layout.filter.width
                                                 layout.filter.height true
                                                 "Filter" filter-border)]
        (set state.filter-buf filter-buf)
        (set state.filter-close filter-close)
        (setup-filter-window state filter-buf)
        ;; Position filter window
        (let [filter-win (vim.fn.bufwinid filter-buf)]
          (when (> filter-win -1)
            (c filter-win {:relative :editor
                           :row layout.filter.row
                           :col layout.filter.col
                           :zindex 50})
            ;(o :winblend 0 {:win filter-win})
            (o :winhighlight "Normal:Normal,FloatBorder:Normal"
               {:win filter-win})
            (vim.fn.prompt_setprompt filter-buf "> "))))
      ;; Create list window using float-win with custom border
      (let [list-border ["├" "─" "┤" "│" "┴" "─" "╰" "│"]
            (list-buf list-close) (float-win state.filtered-items
                                             layout.list.width
                                             layout.list.height false "Results"
                                             list-border)]
        (set state.list-buf list-buf)
        (set state.list-close list-close)
        (setup-list-window state list-buf)
        ;; Position list window with initial title
        (let [list-win (vim.fn.bufwinid list-buf)
              total-items (length state.filtered-items)
              title (.. " Results " state.selected-idx "/" total-items " ")]
          (if (> list-win -1)
              (c list-win {:relative :editor
                           :row layout.list.row
                           :col layout.list.col
                           : title
                           :title_pos :center
                           :zindex 51})))
        ;; Create preview window if enabled
        (if layout.preview
            (let [preview-border ["┬"
                                  "─"
                                  "╮"
                                  "│"
                                  "╯"
                                  "─"
                                  "└"
                                  "│"]
                  (preview-buf preview-close) (float-win [""]
                                                         layout.preview.width
                                                         layout.preview.height
                                                         false "Preview"
                                                         preview-border)]
              (set state.preview-buf preview-buf)
              (set state.preview-close preview-close)
              (setup-preview-window preview-buf config)
              ;; Position preview window
              (let [preview-win (vim.fn.bufwinid preview-buf)]
                (if (> preview-win -1)
                    (c preview-win
                       {:relative :editor
                        :row layout.preview.row
                        :col layout.preview.col})))))
        ;; Setup interactions
        (setup-keymaps state config close-keys select-keys)
        ;; Initial display
        (update-list-display state)
        (update-preview state)
        ;; Focus filter window and enter insert mode
        (let [filter-win (vim.fn.bufwinid state.filter-buf)]
          (when (> filter-win -1)
            (vim.api.nvim_set_current_win filter-win)
            (vim.cmd.startinsert)))))))
