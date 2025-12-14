;; picker/view.fnl - extui-based rendering for picker

(local cmdline (require :vim._extui.cmdline))
(local ext (require :vim._extui.shared))

(local View {})
(set View.__index View)

;; Extmark priorities
(local ext-priority {:prompt 1 :info 2 :select 4 :marker 8 :hl 16 :icon 32 :match 64})

;; Prompt highlight ID
(local prompt-hl-id (vim.api.nvim_get_hl_id_by_name "PickerPrompt"))

(fn get-changedtick []
  (vim.api.nvim_buf_get_changedtick ext.bufs.cmd))

;; Set cmdheight and window height
(fn win-config [win hide height]
  (if (and (= ext.cmdheight 0)
           (not= (. (vim.api.nvim_win_get_config win) :hide) hide))
      (vim.api.nvim_win_set_config win {:hide hide :height (if (not hide) height nil)})
      (not= (vim.api.nvim_win_get_height win) height)
      (vim.api.nvim_win_set_height win height))
  (when (not= vim.o.cmdheight height)
    (vim._with {:noautocmd true :o {:splitkeep :screen}}
               (fn [] (set vim.o.cmdheight height)))
    (ext.msg.set_pos)))

;; Create new View
(fn View.new [self picker]
  (setmetatable {:picker picker
                 :closed false
                 :opts {}
                 :marks {}
                 :win {:height 1}
                 :preview-win nil
                 :preview-timer nil
                 :view-ns (vim.api.nvim_create_namespace "picker:view:ns")
                 :cmdbuff ""
                 :promptlen 0
                 :promptidx 0
                 :curpos [0 0]
                 :offset 0
                 :max-list-height 1
                 :before-draw-tick 0
                 :last-draw-tick 0
                 :cmdline {:srow 0 :erow 0}}
                View))

;; Update prompt position index
(fn View.promptpos [self]
  (set self.promptidx (if self.picker.opts.bottom self.cmdline.erow 0)))

;; Set lines in cmdline buffer
(fn View.setlines [self posstart posend lines]
  (let [diff (- (length lines) (- posend posstart))]
    (when (not= diff 0)
      (let [height (. (vim.api.nvim_win_text_height ext.wins.cmd {}) :all)
            predicted (+ height diff)]
        (self:updatewinheight predicted))))
  (set self.before-draw-tick (get-changedtick))
  (vim.api.nvim_buf_set_lines ext.bufs.cmd posstart posend false lines)
  (set self.last-draw-tick (get-changedtick)))

;; Set extmark
(fn View.mark [self id line col opts]
  (when (and id (. self.marks id))
    (vim._with {:noautocmd true}
               (fn []
                 (vim.api.nvim_buf_del_extmark ext.bufs.cmd self.view-ns (. self.marks id))))
    (tset self.marks id nil))
  (set opts.hl_mode :combine)
  (set opts.invalidate true)
  (var result -1)
  (vim._with {:noautocmd true}
             (fn []
               (let [(ok res) (pcall vim.api.nvim_buf_set_extmark ext.bufs.cmd self.view-ns line col opts)]
                 (when ok (set result res)))))
  (when (and id (>= result 0))
    (tset self.marks id result))
  result)

;; Update window height
(fn View.updatewinheight [self predicted]
  (let [height (math.max 1 (or predicted (. (vim.api.nvim_win_text_height ext.wins.cmd {}) :all)))
        clamped (math.min height self.win.height)]
    (win-config ext.wins.cmd false clamped)))

;; Handle resize events
(fn View.on-resized [self]
  (let [cfg-height self.picker.win.height]
    (set self.win.height
         (if (> cfg-height 1)
             cfg-height
             (* vim.o.lines cfg-height)))
    (set self.win.height (math.max (math.ceil self.win.height) 1))
    (set self.max-list-height (math.max (- self.win.height 1) 1)))
  ;; Force full redraw with new dimensions
  (when (not self.closed)
    (self:update true)))

;; Update scroll offset
(fn View.updateoffset [self]
  (self.picker:fix)
  (if (= self.picker.idx 0)
      (set self.offset 0)
      (do
        (let [_offset (- self.picker.idx self.max-list-height)]
          (when (> _offset self.offset) (set self.offset _offset))
          (when (<= self.picker.idx self.offset) (set self.offset (- self.picker.idx 1))))
        (set self.offset (math.min (math.max 0 self.offset)
                              (math.max 0 (- (length self.picker.matches) self.max-list-height)))))))

;; Render matches list
(fn View.showmatches [self]
  (let [indent (+ (vim.fn.strdisplaywidth self.picker.opts.pointer) 1)
        prefix (string.rep " " indent)
        icon-pad 2
        icon-pad-str (string.rep " " icon-pad)]
    (self:updateoffset)
    (local lines [])
    (local hls [])
    (local icons [])
    (local custom-hls [])
    (local marks [])

    ;; Build lines
    (for [i (+ 1 self.offset) (math.min (length self.picker.matches) (+ self.max-list-height self.offset))]
      (let [m (. self.picker.matches i)
            item (. self.picker.items (. m 1))]
        ;; Get icon
        (var icon nil)
        (var icon-hl nil)
        (when (vim.is_callable self.picker.get-icon)
          (let [(ic hl) (self.picker.get-icon item)]
            (set icon ic)
            (set icon-hl hl)))

        (table.insert icons (if icon [icon icon-hl] false))
        (local icon-str (if icon (.. icon icon-pad-str) ""))

        ;; Get custom highlights
        (var hl nil)
        (when (vim.is_callable self.picker.hl-item)
          (set hl (self.picker.hl-item item)))
        (table.insert custom-hls (or hl false))

        ;; Track marked state
        (table.insert marks (or (. self.picker.marked item.id) false))

        ;; Build line
        (table.insert lines (.. prefix icon-str item.text))
        (table.insert hls (. m 2))))

    ;; Pad if not shrinking
    (when (not self.picker.opts.shrink)
      (for [_ 1 (- self.max-list-height (length lines))]
        (table.insert lines "")))

    ;; Set lines
    (self:setlines self.cmdline.srow self.cmdline.erow lines)
    (set self.cmdline.erow (+ self.cmdline.srow (length lines)))

    ;; Apply highlights
    (for [i 1 (length lines)]
      (let [has-icon (and (. icons i) (. (. icons i) 1))
            icon-indent (if has-icon (+ (length (. (. icons i) 1)) icon-pad) 0)]
        ;; Icon highlight
        (when (and has-icon (. (. icons i) 2))
          (self:mark nil (- (+ self.cmdline.srow i) 1) indent
                     {:end_col (+ indent icon-indent)
                      :hl_group (. (. icons i) 2)
                      :priority ext-priority.icon}))

        ;; Custom highlights
        (let [line-hls (. custom-hls i)]
          (when line-hls
            (each [_ hl (ipairs line-hls)]
              (self:mark nil (- (+ self.cmdline.srow i) 1)
                         (+ indent icon-indent (. (. hl 1) 1))
                         {:end_col (+ indent icon-indent (. (. hl 1) 2))
                          :hl_group (. hl 2)
                          :priority ext-priority.hl}))))

        ;; Sign text
        (when (vim.is_callable self.picker.get-sign)
          (let [match-idx (+ i self.offset)
                m (. self.picker.matches match-idx)
                item (when m (. self.picker.items (. m 1)))]
            (when item
              (let [(sign-text sign-hl) (self.picker.get-sign item)]
                (when sign-text
                  (self:mark nil (- (+ self.cmdline.srow i) 1) (- indent 2)
                             {:virt_text [[sign-text (or sign-hl "Normal")]]
                              :virt_text_pos :overlay
                              :priority ext-priority.marker}))))))

        ;; Marker for multi-selection
        (when (. marks i)
          (self:mark nil (- (+ self.cmdline.srow i) 1) (- indent 1)
                     {:virt_text [[self.picker.opts.marker "PickerMarker"]]
                      :virt_text_pos :overlay
                      :priority ext-priority.marker}))

        ;; Fuzzy match highlights
        (when (. hls i)
          (each [_ pos (ipairs (. hls i))]
            (let [col (+ indent icon-indent pos)]
              (self:mark nil (- (+ self.cmdline.srow i) 1) col
                         {:hl_group "PickerMatch"
                          :end_col (+ col 1)
                          :priority ext-priority.match}))))

        ;; Virtual text
        (when (vim.is_callable self.picker.get-virt-text)
          (let [match-idx (+ i self.offset)
                m (. self.picker.matches match-idx)
                item (when m (. self.picker.items (. m 1)))
                virt-text (when item (self.picker.get-virt-text item))]
            (when virt-text
              (self:mark nil (- (+ self.cmdline.srow i) 1) 0
                         {:virt_text [[virt-text :Comment]]
                          :virt_text_pos :eol
                          :priority ext-priority.info}))))))))

;; Highlight current selection
(fn View.hlselect [self]
  (self:softupdatepreview)
  (self.picker:fix)
  (when (not= self.picker.idx 0)
    (self:updateoffset)
    (let [row (- (math.min (+ self.cmdline.srow (- self.picker.idx self.offset)) self.cmdline.erow) 1)
          row (math.max 0 row)]
      (self:mark :hlselect row 0
                 {:line_hl_group "PickerCurrSel"
                  :priority ext-priority.select}))))

;; Lightweight navigation update (no full redraw)
(fn View.navigate [self]
  (self.picker:fix)
  (local old-offset self.offset)
  (self:updateoffset)
  ;; If offset changed, redraw the list
  (when (not= old-offset self.offset)
    (self:showmatches))
  ;; Just update selection highlight
  (when (> self.picker.idx 0)
    (let [row (- (math.min (+ self.cmdline.srow (- self.picker.idx self.offset)) self.cmdline.erow) 1)
          row (math.max 0 row)]
      (self:mark :hlselect row 0
                 {:line_hl_group "PickerCurrSel"
                  :priority ext-priority.select})))
  ;; Update prompt info
  (self:drawprompt)
  ;; Debounced preview update
  (when self.preview-timer
    (vim.fn.timer_stop self.preview-timer))
  (set self.preview-timer
       (vim.fn.timer_start 50
                           (fn []
                             (set self.preview-timer nil)
                             (when (not self.closed)
                               (self:softupdatepreview))))))

;; Draw prompt info
(fn View.drawprompt [self]
  (self:promptpos)
  (when (and (> self.promptlen 0) (> prompt-hl-id 0))
    (self:mark :prompthl self.promptidx 0
               {:hl_group prompt-hl-id
                :end_col self.promptlen
                :priority ext-priority.prompt})
    (self:mark :promptinfo self.promptidx 0
               {:virt_text [[
                             (string.format "[%d] (%d/%d)"
                                            self.picker.idx
                                            (length self.picker.matches)
                                            (length self.picker.items))
                             "InfoText"]]
                :virt_text_pos :eol_right_align
                :priority ext-priority.info})))

;; Set prompt text in cmdline buffer
(fn View.setprompttext [self content prompt]
  (local lines [])
  (each [line (string.gmatch (.. prompt "\n") "(.-)\n")]
    (table.insert lines (vim.fn.strtrans line)))
  (local promptstr (. lines (length lines)))
  (set self.promptlen (length promptstr))
  (set self.cmdbuff "")
  (each [_ chunk (ipairs content)]
    (set self.cmdbuff (.. self.cmdbuff (. chunk 2))))
  (tset lines (length lines) (.. promptstr (vim.fn.strtrans self.cmdbuff)))
  (self:promptpos)
  (self:setlines self.promptidx (+ self.promptidx 1) lines)
  (vim.fn.prompt_setprompt ext.bufs.cmd promptstr))

;; Main show function (hooked into cmdline)
(fn View.show [self content pos firstc prompt indent level hl-id]
  (set cmdline.level level)
  (set cmdline.indent indent)
  (set cmdline.prompt (or cmdline.prompt (> (length prompt) 0)))
  (when (and cmdline.highlighter cmdline.highlighter.active)
    (tset cmdline.highlighter.active ext.bufs.cmd nil))
  (when (not= ext.msg.cmd.msg_row -1)
    (ext.msg.msg_clear))
  (set ext.msg.virt.last [[] [] [] []])

  (self:clear)

  (self:showmatches)
  (self:setprompttext content (.. firstc prompt (string.rep " " indent)))
  (self:updatecursor pos)
  (self:updatewinheight)
  (self:drawprompt)
  (self:hlselect))

;; Clear cmdline buffer
(fn View.clear [self]
  (set self.cmdline.srow (if self.picker.opts.bottom 0 1))
  (set self.cmdline.erow self.cmdline.srow)
  (self:setlines 0 -1 []))

;; Update cursor position
(fn View.updatecursor [self pos-arg]
  (self:promptpos)
  (var pos pos-arg)
  (when (or (not pos) (< pos 0))
    (let [cursorpos (vim.api.nvim_win_get_cursor ext.wins.cmd)]
      (set pos (- (. cursorpos 2) self.promptlen))))
  (when (or (not= (. self.curpos 1) (+ self.promptidx 1))
            (not= (. self.curpos 2) (+ self.promptlen pos)))
    (when (< pos 0)
      (set pos 0))
    (tset self.curpos 1 (+ self.promptidx 1))
    (tset self.curpos 2 (+ self.promptlen pos))
    (vim._with {:noautocmd true}
               (fn []
                 (pcall vim.api.nvim_win_set_cursor ext.wins.cmd self.curpos)))))

;; Trigger cmdline show
(fn View.trigger-show [self pos]
  (cmdline.cmdline_show
    [[0 self.picker.input]]
    (or pos -1) "" self.picker.prompttext cmdline.indent cmdline.level prompt-hl-id))

;; Update on text change (synchronous for speed)
(fn View.update [self force]
  (if (= (vim.api.nvim_get_current_buf) ext.bufs.cmd)
      (if (and (not force)
               (< self.before-draw-tick self.last-draw-tick)
               (= self.before-draw-tick (- (get-changedtick) 1)))
          (self:drawprompt)
          (do
            ;; Capture cursor position BEFORE any modifications
            (let [cursorpos (vim.api.nvim_win_get_cursor ext.wins.cmd)
                  cursor-col (- (. cursorpos 2) self.promptlen)
                  text (vim.api.nvim_get_current_line)
                  text (string.sub text (+ self.promptlen 1))
                  old-input self.picker.input]
              (set self.picker.input text)
              ;; Direct synchronous update (fast!)
              (self.picker:getmatches)
              ;; Reset index to 1 when filter text changes
              (when (not= old-input text)
                (set self.picker.idx (if self.picker.opts.preselect 1 0)))
              (when (not self.closed)
                (self:trigger-show cursor-col))))))
  false)

;; Save window state
(fn View.saveview [self]
  (set self.save (vim.fn.winsaveview))
  (set self.prevwin (vim.api.nvim_get_current_win)))

;; Restore window state
(fn View.restoreview [self]
  (vim.api.nvim_set_current_win self.prevwin)
  (vim.fn.winrestview self.save))

;; Set/restore window options
(fn View.setopts [self restore]
  (local opts
         {:win {:eventignorewin "all,-FileType,-InsertCharPre,-TextChangedI,-CursorMovedI"
                :winhighlight "Normal:PickerNormal,Search:,CurSearch:,IncSearch:"
                :signcolumn :no
                :wrap false}
          :buf {:filetype :picker
                :buftype :prompt
                :autocomplete false}
          :g {:laststatus (if self.picker.win.hide-statusline 0 nil)
              :showmode false
              :showcmd false}})
  (each [level o (pairs opts)]
    (when (not (. self.opts level))
      (tset self.opts level {}))
    (local props {:scope (if (= level :g) :global :local)
                  :buf (if (= level :buf) ext.bufs.cmd nil)
                  :win (if (= level :win) ext.wins.cmd nil)})
    (each [name value (pairs o)]
      (if restore
          (vim.api.nvim_set_option_value name (. (. self.opts level) name) props)
          (do
            (tset (. self.opts level) name (vim.api.nvim_get_option_value name props))
            (vim.api.nvim_set_option_value name value props))))))

;; Open the view
(fn View.open [self]
  (when self.picker
    (ext.check_targets)
    (set self.prev-show cmdline.cmdline_show)

    (vim.schedule
      (fn []
        (set self.augroup (vim.api.nvim_create_augroup "picker:group" {:clear true}))

        ;; Close on leave
        (vim.api.nvim_create_autocmd [:CmdlineLeave :ModeChanged]
                                     {:group self.augroup
                                      :once true
                                      :callback (fn [] (self:close))})

        ;; Handle resize
        (vim.api.nvim_create_autocmd [:VimResized :WinEnter]
                                     {:group self.augroup
                                      :callback (fn [] (self:on-resized))})

        ;; Update on window enter
        (vim.api.nvim_create_autocmd :WinEnter
                                     {:group self.augroup
                                      :callback (fn [] (self:update true))})

        ;; Update on text change
        (vim.api.nvim_create_autocmd :TextChangedI
                                     {:group self.augroup
                                      :buffer ext.bufs.cmd
                                      :callback (fn [] (self:update))})))

    ;; Hook cmdline show
    (set cmdline.cmdline_show (fn [...] (self:show ...)))
    (set cmdline.indent 1)
    (set cmdline.level 0)

    (self:saveview)
    (self:on-resized)  ;; Calculate height before first render
    (self:trigger-show)

    (vim._with {:noautocmd true}
               (fn [] (vim.api.nvim_set_current_win ext.wins.cmd)))

    (self:setopts)
    (self:updatecursor)
    (vim._with {:noautocmd true}
               (fn [] (vim.cmd.startinsert)))

    ;; Trigger WinEnter
    (vim.schedule
      (fn []
        (vim._with {:win ext.wins.cmd :wo {:eventignorewin ""}}
                   (fn [] (vim.api.nvim_exec_autocmds :WinEnter {})))
        ;; Open preview by default if configured
        (when self.picker.win.preview-default
          (self:updatepreview))))))

;; Hide the view
(fn View.hide [self]
  (vim.fn.clearmatches ext.wins.cmd)
  (vim.api.nvim_win_set_cursor ext.wins.cmd [1 0])
  (vim.api.nvim_buf_set_lines ext.bufs.cmd 0 -1 false [])

  ;; Capture prompt state before clearing
  (local was-prompt cmdline.prompt)
  (set cmdline.prompt false)
  (set cmdline.level 0)
  (win-config ext.wins.cmd true ext.cmdheight)

  ;; Schedule cleanup if needed
  (vim.schedule
    (fn []
      (when (and was-prompt (not cmdline.prompt))
        (pcall (fn []
                 (vim.api.nvim_buf_set_lines ext.bufs.cmd 0 -1 false [])
                 (vim.api.nvim_buf_set_lines ext.bufs.dialog 0 -1 false [])
                 (vim.api.nvim_win_set_config ext.wins.dialog {:hide true})
                 (vim.on_key nil ext.msg.dialog_on_key))))
      (vim.schedule (fn [] (set cmdline.level -1))))))

;; Close the view
(fn View.close [self]
  (when (not self.closed)
    (set cmdline.cmdline_show self.prev-show)
    (self:closepreview)
    (vim.schedule
      (fn []
        (pcall vim.api.nvim_del_augroup_by_id self.augroup)
        (pcall vim.api.nvim_buf_detach ext.bufs.cmd)
        (vim.cmd.stopinsert)
        (self:setopts true)
        (self:clear)
        (set self.cmdline.srow 0)
        (set self.cmdline.erow 0)
        (self:hide)
        (self:restoreview)
        (vim.cmd.redraw)
        (set self.closed true)
        (self.picker:close)))))

;; Preview functions
(fn View.openpreview [self]
  (if (= self.picker.idx 0)
      -1
      (let [m (. self.picker.matches self.picker.idx)
            item (. self.picker.items (. m 1))]
        (if (and item self.picker.preview-item (vim.is_callable self.picker.preview-item))
            (self.picker.preview-item item.v)
            -1))))

;; Calculate preview row - glued to top of picker list
(fn View.previewrow [self]
  (let [border (if (= vim.o.winborder :none) 0 2)]
    (- vim.o.lines vim.o.cmdheight self.win.height border)))

;; Reposition preview window to stay glued to picker
(fn View.repositionpreview [self]
  (when (and self.preview-win (vim.api.nvim_win_is_valid self.preview-win))
    (vim.api.nvim_win_set_config self.preview-win
                                  {:relative :editor
                                   :row (self:previewrow)
                                   :col 0
                                   :width vim.o.columns
                                   :height self.win.height})))

(fn View.updatepreview [self]
  (let [(buf on-win) (self:openpreview)]
    (when (>= buf 0)
      (if (not self.preview-win)
          (let [preview-opts (and self.picker.win.preview-opts
                                  (vim.is_callable self.picker.win.preview-opts)
                                  (self.picker.win.preview-opts self))]
            (set self.preview-win
                 (vim.api.nvim_open_win
                   buf false
                   (vim.tbl_extend :force
                                   {:relative :editor
                                    :width vim.o.columns
                                    :height self.win.height
                                    :col 0
                                    :row (self:previewrow)}
                                   (or preview-opts {})))))
          (do
            (vim.api.nvim_win_set_buf self.preview-win buf)
            (self:repositionpreview)))
      (vim._with {:win self.preview-win :noautocmd true}
                 (fn []
                   (vim.api.nvim_set_option_value :previewwindow true {:scope :local})))
      (when (and on-win (vim.is_callable on-win))
        (on-win self.preview-win)))))

(fn View.softupdatepreview [self]
  (if (= self.picker.idx 0)
      (self:closepreview)
      (do
        ;; Reopen preview if it was closed and preview-default is on
        (when (and (not self.preview-win) self.picker.win.preview-default)
          (self:updatepreview))
        (when self.preview-win
          (self:updatepreview)
          (self:repositionpreview)))))

(fn View.togglepreview [self]
  (if self.preview-win
      (self:closepreview)
      (self:updatepreview)))

(fn View.closepreview [self]
  (when self.preview-win
    (vim.api.nvim_win_close self.preview-win true)
    (set self.preview-win nil)))

(fn View.scrollpreview [self direction]
  (when (and self.preview-win (vim.api.nvim_win_is_valid self.preview-win))
    (let [lines (if (= direction :up) -5 5)]
      (vim.api.nvim_win_call self.preview-win
                             #(vim.cmd (string.format "normal! %dj" lines))))))

View
