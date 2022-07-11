(fn max [items]
  (accumulate [max 0 _ item (ipairs items)]
    (let [x (length item)]
      (if (> x max) x max))))

;; fnlfmt: skip
(fn float-win [items width height modifiable prompt]
  (let [b (vim.api.nvim_create_buf false true)]
    (fn buf-opts [opts]
      (each [k v (pairs opts)]
        (vim.api.nvim_buf_set_option b k v)))

    (buf-opts {:swapfile false :bufhidden :wipe :filetype :UIInput})
    (vim.api.nvim_buf_set_lines b 0 -1 true items)
    (buf-opts {: modifiable})

    (let [oTitlestring vim.opt.titlestring
          border ["┏" "━" "┓" "┃" "┛" "━" "┗" "┃"]
          win-open-opts {: width : height :row 1 :col 0
                         :relative :cursor :anchor :NW
                         :style :minimal : border}
          win-set-opts {:winblend 90 :winhighlight "CursorLine:PmenuSel,NormalFloat:Pmenu"
                        :cursorline (not modifiable) :cursorlineopt :both}
          w (vim.api.nvim_open_win b true win-open-opts)]
      (each [k v (pairs win-set-opts)]
        (vim.api.nvim_win_set_option w k v))
      (set vim.opt.titlestring
           (or prompt (if modifiable "Please enter:" "Please select:")))

      (fn close []
        (if modifiable (vim.cmd :stopinsert))
        (set vim.opt.titlestring oTitlestring)
        (vim.api.nvim_win_close w true))

      (values b close))))

(fn vim.ui.input [opts on-confirm]
  (vim.validate {:on_confirm [on-confirm :function false]})
  (set-forcibly! opts (or (and (and opts (not (vim.tbl_isempty opts))) opts)
                          (vim.empty_dict)))
  (let [on-confirm #(if (> (length $) 0) (on-confirm $) (on-confirm))]
    (let [def opts.default
          w (if (and def (> (length def) 0)) (+ (length def) 10) 25)
          (b close) (float-win [(or opts.default "")] w 1 true opts.prompt)]
      (fn choose []
        (let [line (vim.api.nvim_get_current_line)]
          (on-confirm line)
          (close)))

      (vim.keymap.set :i :<CR> choose {:buffer b :silent true})
      (vim.keymap.set :i :<Esc> close {:buffer b :silent true})
      (vim.fn.cursor 0 (+ 1 (length opts.default)))
      (vim.cmd :startinsert))))

(fn vim.ui.select [items opts on-choice]
  (vim.validate {:on_choice [on-choice :function false]
                 :items [items :table false]})
  (set-forcibly! opts (or opts {}))
  (let [fmt (or opts.format_item tostring)
        choices (icollect [_ item (ipairs items)]
                  (.. (fmt item) " "))
        on-choice #(if (or (< $ 1) (> $ (length items))) (on-choice)
                       (on-choice (. items $) $))]
    (let [(b close) (float-win choices (max choices) (length choices) false
                               opts.prompt)]
      (fn choose []
        (let [row (vim.fn.line ".")]
          (on-choice row)
          (close)))

      (each [lhsx rhs (pairs {[:<CR> :<Space> :<2-LeftMouse>] choose
                              [:<C-c> :<Esc>] close
                              [:<Left> :<ScrollWheelUp>] :<Up>
                              [:<Right> :<ScrollWheelDown>] :<Down>})]
        (each [_ lhs (ipairs lhsx)]
          (vim.keymap.set :n lhs rhs {:buffer b :silent true}))))))

