(local {: float-win} (require :util))

;; fnlfmt: skip
(local default-config {:width 120 :height 30
                       :preview {:enabled true :width-ratio 0.5 :treesitter true :number false}
                       :fuzzy {:enabled true :limit 50 :matchseq 1 :key nil}
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
                     :preview-enabled true
                     :preview-fn nil
                     :on-select nil
                     :source-fn nil
                     :setup-list-fn nil
                     :config {}})

(local o vim.api.nvim_set_option_value)

;; fnlfmt: skip
(fn calculate-layout [config preview-enabled]
  (let [total-width config.width
        total-height config.height
        preview-width (if preview-enabled (math.floor (* total-width config.preview.width-ratio)) 0)
        list-width (- total-width preview-width)
        filter-height 1
        list-height (- total-height filter-height 1)
        ; Center the whole picker on screen
        start-row (math.floor (/ (- vim.o.lines total-height) 2))
        start-col (math.floor (/ (- vim.o.columns total-width) 2))]
    {:filter {:width list-width :height filter-height :row start-row :col start-col}
     :list {:width list-width :height list-height :row (+ start-row filter-height 1) :col start-col}
     :preview (if preview-enabled {:width preview-width :height total-height :row start-row :col (+ start-col list-width 1)})}))

(fn update-filter [filter-text]
  (set picker-state.filter-text filter-text)
  (if (= (length filter-text) 0)
      (set picker-state.filtered-items picker-state.all-items)
      (if picker-state.config.fuzzy.enabled
          ;; Check for strict vs fuzzy mode
          (let [strict-mode (string.find filter-text "^'")
                search-text (if strict-mode (string.sub filter-text 2)
                                filter-text)]
            (if strict-mode
                ;; Strict matching - filter items that contain the search text
                (set picker-state.filtered-items
                     (icollect [_ item (ipairs picker-state.all-items)]
                       (if (string.find item search-text 1 true)
                           item)))
                ;; Fuzzy matching with vim.fn.matchfuzzy
                (let [fuzzy-opts {:limit picker-state.config.fuzzy.limit
                                  :matchseq picker-state.config.fuzzy.matchseq}
                      fuzzy-opts (if picker-state.config.fuzzy.key
                                     (vim.tbl_extend :force fuzzy-opts
                                                     {:key picker-state.config.fuzzy.key})
                                     fuzzy-opts)]
                  (set picker-state.filtered-items
                       (vim.fn.matchfuzzy picker-state.all-items search-text
                                          fuzzy-opts)))))
          ;; Fallback to source function filtering
          (set picker-state.filtered-items
               (picker-state.source-fn filter-text nil))))
  (set picker-state.selected-idx 1))

(fn update-list-display []
  (when picker-state.list-buf
    (o :modifiable true {:buf picker-state.list-buf})
    (vim.api.nvim_buf_set_lines picker-state.list-buf 0 -1 false
                                picker-state.filtered-items)
    ;; Call setup-list-fn if provided
    (if picker-state.setup-list-fn
        (picker-state.setup-list-fn picker-state.list-buf
                                    picker-state.filtered-items))
    (o :modifiable false {:buf picker-state.list-buf})
    (o :modified false {:buf picker-state.list-buf})
    (let [list-win (vim.fn.bufwinid picker-state.list-buf)]
      (if (> list-win -1)
          (vim.api.nvim_win_set_cursor list-win [picker-state.selected-idx 0])))))

(fn update-preview []
  (if (and picker-state.preview-buf picker-state.preview-fn
           (> (length picker-state.filtered-items) 0))
      (let [current-item (. picker-state.filtered-items
                            picker-state.selected-idx)]
        (if current-item
            (let [preview-content (picker-state.preview-fn current-item)]
              (o :modifiable true {:buf picker-state.preview-buf})
              (vim.api.nvim_buf_set_lines picker-state.preview-buf 0 -1 false
                                          (if (= (type preview-content) :table)
                                              preview-content
                                              [preview-content]))
              ;; Set filetype for Treesitter highlighting based on current item
              (if (and (= (type current-item) :string)
                       picker-state.config.preview.treesitter)
                  (let [filetype (vim.filetype.match {:filename current-item})]
                    (when filetype
                      ;; Set filetype for Treesitter
                      (o :filetype filetype {:buf picker-state.preview-buf})
                      ;; Enable Treesitter highlighting if available
                      (pcall #(vim.treesitter.start picker-state.preview-buf
                                                    filetype)))))
              (o :modifiable false {:buf picker-state.preview-buf})
              (o :modified false {:buf picker-state.preview-buf}))))))

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
                  (each [_ close-fn (pairs [picker-state.filter-close
                                            picker-state.list-close
                                            picker-state.preview-close])]
                    (if (and close-fn (= (type close-fn) :function))
                        (pcall close-fn)))
                  (each [_ key (ipairs [:filter-buf :filter-close :list-buf :list-close :preview-buf :preview-close])]
                    (tset picker-state key nil))
                  (set picker-state.all-items []))))

(fn select-current []
  (if (and picker-state.on-select (> (length picker-state.filtered-items) 0))
      (let [selected-item (. picker-state.filtered-items
                             picker-state.selected-idx)
            on-select-fn picker-state.on-select]
        (close-picker)
        (vim.schedule #(on-select-fn selected-item picker-state.selected-idx)))))

;; fnlfmt: skip
(fn setup-filter-window [filter-buf _config]
  (o :buftype :prompt {:buf filter-buf})
  (vim.api.nvim_buf_call filter-buf #(vim.cmd "setl nobl bt=prompt bh=delete noswf"))
  (vim.api.nvim_create_autocmd [:TextChanged :TextChangedI]
                               {:buffer filter-buf
                                :callback #(let [lines (vim.api.nvim_buf_get_lines filter-buf 0 -1 false)
                                                 filter-text (or (and (> (length lines) 0) (string.sub (. lines 1) 3)) "")]
                                             (update-filter filter-text)
                                             (update-list-display)
                                             (update-preview)
                                             ;; Reset modified state to prevent E37
                                             (vim.api.nvim_set_option_value :modified false {:buf filter-buf}))}))

(fn setup-list-window [list-buf]
  (vim.api.nvim_buf_call list-buf #(vim.cmd "Scratchify"))
  (let [list-win (vim.fn.bufwinid list-buf)]
    (when (> list-win -1)
      (o :cursorline true {:win list-win})
      (o :winblend 0 {:win list-win})
      (o :winhighlight "CursorLine:PmenuSel,FloatBorder:Normal,Cursor:CursorLine" {:win list-win}))))

(fn setup-preview-window [preview-buf config]
  (vim.api.nvim_buf_call preview-buf #(vim.cmd "Scratchify"))
  (let [preview-win (vim.fn.bufwinid preview-buf)]
    (when (> preview-win -1)
      (o :wrap false {:win preview-win})
      (o :number config.preview.number {:win preview-win})
      (o :cursorline false {:win preview-win})
      (o :winblend 0 {:win preview-win})
      (o :winhighlight "Normal:Normal,FloatBorder:Normal" {:win preview-win})
      (o :foldenable false {:win preview-win})
      (if config.preview.treesitter
          (o :syntax :enable {:buf preview-buf})))))

(fn setup-keymaps [_config close-keys select-keys]
  (let [filter-opts {:buffer picker-state.filter-buf :silent true}
        list-opts {:buffer picker-state.list-buf :silent true}]
    ;; Filter window keymaps (insert mode)
    (each [_ key (ipairs close-keys)]
      (vim.keymap.set :i key close-picker filter-opts))
    (each [_ key (ipairs select-keys)]
      (vim.keymap.set :i key select-current filter-opts))
    ;; Navigation in filter mode
    (vim.keymap.set :i :<Up> #(move-selection :up) filter-opts)
    (vim.keymap.set :i :<Down> #(move-selection :down) filter-opts)
    (vim.keymap.set :i :<C-n> #(move-selection :down) filter-opts)
    (vim.keymap.set :i :<C-p> #(move-selection :up) filter-opts)
    ;; Disable global quote autopair in filter window
    (vim.keymap.set :i "'" "'" filter-opts)
    ;; Preview scrolling from filter window (insert mode) - using Alt keys
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
    ;; List window keymaps (normal mode)
    (each [_ key (ipairs close-keys)]
      (vim.keymap.set :n key close-picker list-opts))
    (each [_ key (ipairs select-keys)]
      (vim.keymap.set :n key select-current list-opts))
    (vim.keymap.set :n :j #(move-selection :down) list-opts)
    (vim.keymap.set :n :k #(move-selection :up) list-opts)
    (vim.keymap.set :n :<Down> #(move-selection :down) list-opts)
    (vim.keymap.set :n :<Up> #(move-selection :up) list-opts)
    ;; Preview scrolling from results window
    (vim.keymap.set :n :<M-k>
                    #(if picker-state.preview-buf
                         (let [preview-win (vim.fn.bufwinid picker-state.preview-buf)]
                           (if (> preview-win -1)
                               (vim.fn.win_execute preview-win "normal! 5k"))))
                    list-opts)
    (vim.keymap.set :n :<M-j>
                    #(if picker-state.preview-buf
                         (let [preview-win (vim.fn.bufwinid picker-state.preview-buf)]
                           (if (> preview-win -1)
                               (vim.fn.win_execute preview-win "normal! 5j"))))
                    list-opts)
    ;; Focus filter window keymap
    (vim.keymap.set :n ":"
                    #(let [filter-win (vim.fn.bufwinid picker-state.filter-buf)]
                       (when (> filter-win -1)
                         (vim.api.nvim_set_current_win filter-win)
                         (vim.cmd.startinsert))) list-opts)
    ;; Preview window keymaps if preview exists
    (when picker-state.preview-buf
      (let [preview-opts {:buffer picker-state.preview-buf :silent true}]
        (each [_ key (ipairs close-keys)]
          (vim.keymap.set :n key close-picker preview-opts))
        (each [_ key (ipairs select-keys)]
          (vim.keymap.set :n key select-current preview-opts))
        ;; Focus filter window from preview
        (vim.keymap.set :n ":"
                        #(let [filter-win (vim.fn.bufwinid picker-state.filter-buf)]
                           (when (> filter-win -1)
                             (vim.api.nvim_set_current_win filter-win)
                             (vim.cmd.startinsert)))
                        preview-opts)))))

(fn [source-fn opts]
  (vim.validate {:source-fn [source-fn :function]
                 :on-select [opts.on-select :function]})
  (let [config (vim.tbl_deep_extend :force default-config (or opts.config {}))
        close-keys config.keymaps.close
        select-keys config.keymaps.select]
    ;; Initialize state
    (set picker-state.source-fn source-fn)
    (set picker-state.preview-fn opts.preview-fn)
    (set picker-state.on-select opts.on-select)
    (set picker-state.setup-list-fn opts.setup-list-fn)
    (set picker-state.config config)
    (set picker-state.preview-enabled
         (and config.preview.enabled (not= opts.preview-fn nil)))
    ;; Get initial items
    (set picker-state.items (source-fn "" nil))
    (set picker-state.all-items picker-state.items)
    (set picker-state.filtered-items picker-state.items)
    (set picker-state.selected-idx 1)
    (set picker-state.filter-text "")
    ;; Calculate layout
    (let [layout (calculate-layout config picker-state.preview-enabled)]
      ;; Create filter window using float-win with custom border
      (let [filter-border ["╭" "─" "┬" "│" "┤" "─" "├" "│"]
            (filter-buf filter-close) (float-win [""] layout.filter.width
                                                 layout.filter.height true
                                                 "Filter" filter-border)]
        (set picker-state.filter-buf filter-buf)
        (set picker-state.filter-close filter-close)
        (setup-filter-window filter-buf config)
        ;; Position filter window
        (let [filter-win (vim.fn.bufwinid filter-buf)]
          (when (> filter-win -1)
            (vim.api.nvim_win_set_config filter-win
                                         {:relative :editor
                                          :row layout.filter.row
                                          :col layout.filter.col})
            (o :winblend 0 {:win filter-win})
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
              (vim.api.nvim_win_set_config list-win
                                           {:relative :editor
                                            :row layout.list.row
                                            :col layout.list.col
                                            :title "Results"
                                            :title_pos :center}))))
      ;; Create preview window if enabled
      (if layout.preview
          (let [preview-border ["┌" "─" "╮" "│" "╯" "─" "└" "│"]
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
                  (vim.api.nvim_win_set_config preview-win
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
          (vim.cmd.startinsert))))))
