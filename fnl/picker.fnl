(local {: float-win} (require :util))

;; fnlfmt: skip
(local default-config {:preview {:width-ratio 0.5 :number false}
                       :keymaps {:close [:<Esc> :<C-c>]
                                 :select [:<CR> :<Tab>]
                                 :preview-toggle [:<C-p>]
                                 :scroll-preview-up [:<C-u>]
                                 :scroll-preview-down [:<C-d>]}
                       :prompt "Select: "})

(local picker-state {:filter-buf nil
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
                     :source-fn nil
                     :setup-list-fn nil
                     :config {}})

(var original-win nil)

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

(fn update-filter [filter-text]
  (set picker-state.filter-text filter-text)
  (if (= (length filter-text) 0)
      (set picker-state.filtered-items picker-state.all-items)
      (let [strict-mode (string.find filter-text "^'")
            search-text (if strict-mode (string.sub filter-text 2) filter-text)]
        (set picker-state.filtered-items
             (if strict-mode
                 (vim.fn.filter picker-state.all-items #($2:find search-text))
                 (vim.fn.matchfuzzy picker-state.all-items search-text)))))
  (set picker-state.selected-idx 1))

(fn update-list-display []
  (let [buf picker-state.list-buf
        items picker-state.filtered-items]
    (when buf
      (o :modifiable true {: buf})
      (vim.api.nvim_buf_set_lines buf 0 -1 false items)
      (if picker-state.setup-list-fn
          (picker-state.setup-list-fn buf items))
      (o :modifiable false {: buf})
      (o :modified false {: buf})
      (let [list-win (vim.fn.bufwinid buf)]
        (if (> list-win -1)
            (let [total-items (length items)
                  idx picker-state.selected-idx
                  title (.. " Results " idx "/" total-items " ")]
              (c list-win {: title :title_pos :center})
              (vim.api.nvim_win_set_cursor list-win [idx 0])))))))

(fn update-preview []
  (if (and picker-state.preview-buf picker-state.preview-fn
           (> (length picker-state.filtered-items) 0))
      (let [current-item (. picker-state.filtered-items
                            picker-state.selected-idx)]
        (if current-item
            (let [preview-content (picker-state.preview-fn current-item
                                                           picker-state.selected-idx)]
              (o :modifiable true {:buf picker-state.preview-buf})
              ;; All preview functions now return enhanced format
              (vim.api.nvim_buf_set_lines picker-state.preview-buf 0 -1 false
                                          preview-content.content)
              ;; Set filetype based on filename if available
              (when preview-content.filename
                (let [filetype (vim.filetype.match {:filename preview-content.filename})]
                  (when filetype
                    (o :filetype filetype {:buf picker-state.preview-buf})
                    (pcall #(vim.treesitter.start picker-state.preview-buf
                                                  filetype)))))
              ;; Position cursor on specific line if provided
              (when preview-content.line
                (let [preview-win (vim.fn.bufwinid picker-state.preview-buf)]
                  (when (> preview-win -1)
                    (vim.api.nvim_win_set_cursor preview-win
                                                 [preview-content.line 0])
                    (vim.api.nvim_win_call preview-win #(vim.cmd "normal! zz")))))
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
                  (vim.api.nvim_buf_clear_namespace picker-state.preview-buf ns
                                                    0 -1)
                  ;; Highlight the entire line with a subtle background
                  (vim.api.nvim_buf_set_extmark picker-state.preview-buf ns
                                                diag.lnum 0
                                                {:end_line (+ diag.lnum 1)
                                                 :hl_group line-hl
                                                 :priority 50})
                  ;; Apply diagnostic underline to the specific range
                  (when (and diag.col (>= diag.col 0))
                    (let [end-col (or diag.end_col (+ diag.col 1))]
                      (vim.api.nvim_buf_set_extmark picker-state.preview-buf ns
                                                    diag.lnum diag.col
                                                    {:end_col end-col
                                                     :hl_group underline-hl
                                                     :priority 100})))))
              (o :modifiable false {:buf picker-state.preview-buf})
              (o :modified false {:buf picker-state.preview-buf}))
            ;; Update preview window title with footer info
            (if picker-state.preview-fn
                (let [preview-win (vim.fn.bufwinid picker-state.preview-buf)]
                  (if (> preview-win -1)
                      (let [cursor (vim.api.nvim_win_get_cursor preview-win)
                            line (. cursor 1)
                            total-lines (vim.api.nvim_buf_line_count picker-state.preview-buf)
                            percentage (if (> total-lines 0)
                                           (math.floor (* (/ line total-lines)
                                                          100))
                                           0)
                            title (.. " Preview " percentage "% ")]
                        (c preview-win {:title title :title_pos :center})))))))))

(fn move-selection [direction]
  (let [max-idx (length picker-state.filtered-items)]
    (when (> max-idx 0)
      (set picker-state.selected-idx
           (case direction
             :up (math.max 1 (- picker-state.selected-idx 1))
             :down (math.min max-idx (+ picker-state.selected-idx 1))))
      (update-list-display)
      (update-preview))))

;; fnlfmt: skip
(fn close-picker []
    (vim.schedule (fn []
                    (each [_ close-fn (pairs [picker-state.filter-close picker-state.list-close picker-state.preview-close])]
                      (if (and close-fn (= (type close-fn) :function)) (pcall close-fn)))
                    (each [_ key (ipairs [:filter-buf :filter-close :list-buf :list-close :preview-buf :preview-close])]
                      (tset picker-state key nil))
                    (set picker-state.all-items []))))

(fn select-current []
  (if (and picker-state.on-select (> (length picker-state.filtered-items) 0))
      (let [selected-item (. picker-state.filtered-items
                             picker-state.selected-idx)
            on-select-fn picker-state.on-select]
        (close-picker)
        (vim.schedule #(on-select-fn selected-item picker-state.selected-idx
                                     original-win)))))

;; fnlfmt: skip
(fn setup-filter-window [buf]
    (o :buftype :prompt {: buf})
    (vim.api.nvim_buf_call buf #(vim.cmd "setl nobl bt=prompt bh=delete noswf"))
    (vim.api.nvim_create_autocmd [:TextChanged :TextChangedI]
                                 {:buffer buf
                                  :callback #(let [lines (vim.api.nvim_buf_get_lines buf 0 -1 false)
                                                   filter-text (or (and (> (length lines) 0) (string.sub (. lines 1) 3)) "")]
                                               (update-filter filter-text)
                                               (update-list-display)
                                               (update-preview)
                                               ;; Reset modified state to prevent E37
                                               (vim.api.nvim_set_option_value :modified false {: buf}))}))

(fn setup-list-window [buf]
  (vim.api.nvim_buf_call buf #(vim.cmd "Scratchify"))
  (let [win (vim.fn.bufwinid buf)]
    (when (> win -1)
      (o :cursorline true {: win})
      (o :winhighlight
         "CursorLine:PmenuSel,FloatBorder:Normal,Cursor:CursorLine" {: win}))))

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

(fn setup-keymaps [_config close-keys select-keys]
  (let [filter-opts {:buffer picker-state.filter-buf :silent true}
        list-opts {:buffer picker-state.list-buf :silent true}]
    (each [_ key (ipairs close-keys)]
      (vim.keymap.set :i key close-picker filter-opts))
    (each [_ key (ipairs select-keys)]
      (vim.keymap.set :i key select-current filter-opts))
    (vim.keymap.set :i :<Up> #(move-selection :up) filter-opts)
    (vim.keymap.set :i :<Down> #(move-selection :down) filter-opts)
    (vim.keymap.set :i :<C-n> #(move-selection :down) filter-opts)
    (vim.keymap.set :i :<C-p> #(move-selection :up) filter-opts)
    (vim.keymap.set :i "'" "'" filter-opts)
    (vim.keymap.set :i :<M-k>
                    #(if picker-state.preview-buf
                         (let [preview-win (vim.fn.bufwinid picker-state.preview-buf)]
                           (if (> preview-win -1)
                               (vim.fn.win_execute preview-win "normal! 5k"))))
                    filter-opts)
    (vim.keymap.set :i :<M-j>
                    #(if picker-state.preview-buf
                         (let [preview-win (vim.fn.bufwinid picker-state.preview-buf)]
                           (if (> preview-win -1)
                               (vim.fn.win_execute preview-win "normal! 5j"))))
                    filter-opts)
    (each [_ key (ipairs close-keys)]
      (vim.keymap.set :n key close-picker list-opts))
    (each [_ key (ipairs select-keys)]
      (vim.keymap.set :n key select-current list-opts))
    (vim.keymap.set :n :j #(move-selection :down) list-opts)
    (vim.keymap.set :n :k #(move-selection :up) list-opts)
    (vim.keymap.set :n :<Down> #(move-selection :down) list-opts)
    (vim.keymap.set :n :<Up> #(move-selection :up) list-opts)
    (vim.keymap.set :n ":"
                    #(let [filter-win (vim.fn.bufwinid picker-state.filter-buf)]
                       (when (> filter-win -1)
                         (vim.api.nvim_set_current_win filter-win)
                         (vim.cmd.startinsert))) list-opts)
    (if picker-state.preview-buf
        (let [preview-opts {:buffer picker-state.preview-buf :silent true}]
          (each [_ key (ipairs close-keys)]
            (vim.keymap.set :n key close-picker preview-opts))
          (each [_ key (ipairs select-keys)]
            (vim.keymap.set :n key select-current preview-opts))
          (vim.keymap.set :n ":"
                          #(let [filter-win (vim.fn.bufwinid picker-state.filter-buf)]
                             (when (> filter-win -1)
                               (vim.api.nvim_set_current_win filter-win)
                               (vim.cmd.startinsert)))
                          preview-opts)))))

(fn [source-fn opts]
  (vim.validate {:source-fn [source-fn :function]
                 :on-select [opts.on-select :function]})
  (set original-win (vim.api.nvim_get_current_win))
  (let [config (vim.tbl_deep_extend :force default-config (or opts.config {}))
        close-keys config.keymaps.close
        select-keys config.keymaps.select
        preview-enabled (not= opts.preview-fn nil)]
    ;; Initialize state
    (set picker-state.source-fn source-fn)
    (set picker-state.preview-fn opts.preview-fn)
    (set picker-state.on-select opts.on-select)
    (set picker-state.setup-list-fn opts.setup-list-fn)
    (set picker-state.config config)
    ;; Get initial items
    (set picker-state.items (source-fn "" nil))
    (set picker-state.all-items picker-state.items)
    (set picker-state.filtered-items picker-state.items)
    (set picker-state.selected-idx 1)
    (set picker-state.filter-text "")
    ;; Calculate layout
    (let [layout (calculate-layout config preview-enabled)]
      ;; Create filter window using float-win with custom border
      (let [filter-border ["╭" "─" "┬" "│" "┤" "─" "├" "│"]
            (filter-buf filter-close) (float-win [""] layout.filter.width
                                                 layout.filter.height true
                                                 "Filter" filter-border)]
        (set picker-state.filter-buf filter-buf)
        (set picker-state.filter-close filter-close)
        (setup-filter-window filter-buf)
        ;; Position filter window
        (let [filter-win (vim.fn.bufwinid filter-buf)]
          (when (> filter-win -1)
            (c filter-win {:relative :editor
                           :row layout.filter.row
                           :col layout.filter.col})
            ;(o :winblend 0 {:win filter-win})
            (o :winhighlight "FloatBorder:Normal" {:win filter-win})
            (vim.fn.prompt_setprompt filter-buf "> "))))
      ;; Create list window using float-win with custom border
      (let [list-border ["├" "─" "┤" "│" "┴" "─" "╰" "│"]
            (list-buf list-close) (float-win picker-state.filtered-items
                                             layout.list.width
                                             layout.list.height false "Results"
                                             list-border)]
        (set picker-state.list-buf list-buf)
        (set picker-state.list-close list-close)
        (setup-list-window list-buf)
        ;; Position list window
        (let [list-win (vim.fn.bufwinid list-buf)]
          (if (> list-win -1)
              (c list-win {:relative :editor
                           :row layout.list.row
                           :col layout.list.col})))
        ;; Create preview window if enabled
        (if layout.preview
            (let [preview-border ["┌"
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
              (set picker-state.preview-buf preview-buf)
              (set picker-state.preview-close preview-close)
              (setup-preview-window preview-buf config)
              ;; Position preview window
              (let [preview-win (vim.fn.bufwinid preview-buf)]
                (if (> preview-win -1)
                    (c preview-win
                       {:relative :editor
                        :row layout.preview.row
                        :col layout.preview.col})))))
        ;; Setup interactions
        (setup-keymaps config close-keys select-keys)
        ;; Initial display
        (update-list-display)
        (update-preview)
        ;; Focus filter window and enter insert mode
        (let [filter-win (vim.fn.bufwinid picker-state.filter-buf)]
          (when (> filter-win -1)
            (vim.api.nvim_set_current_win filter-win)
            (vim.cmd.startinsert)))))))
