;; https://github.com/neovim/neovim/pull/13896
;; https://github.com/neovim/neovim/pull/13896#issuecomment-774680224
(fn get-range []
  (var [_ l1] (vim.fn.getpos :v))
  (var [_ l2] (vim.fn.getcurpos))
  (when (= l1 l2)
    (set l1 1)
    (set l2 (vim.fn.line "$")))
  (when (> l1 l2)
    (local tmp l1)
    (set l1 l2)
    (set l2 tmp))
  (values l1 l2))

(fn get-selection []
  (let [(l1 l2) (get-range)
        lines (vim.fn.getline l1 l2)
        text (table.concat lines "\n")]
    text))

(fn max [items]
  (accumulate [max 0 _ item (ipairs items)]
    (let [x (length item)]
      (if (> x max) x max))))

;; fnlfmt: skip
(fn float-win [items width height modifiable title]
  (set-forcibly! title (.. " " (vim.fn.trim title ": ") " "))
  (let [buf (vim.api.nvim_create_buf false true)]
    (fn buf-opts [opts]
      (each [k v (pairs opts)]
        (vim.api.nvim_set_option_value k v {: buf})))

    (buf-opts {:swapfile false :bufhidden :wipe :filetype :UIInput})
    (vim.api.nvim_buf_set_lines buf 0 -1 true items)
    (buf-opts {: modifiable})

    (let [border :rounded ; ["┏" "━" "┓" "┃" "┛" "━" "┗" "┃"]
          win-open-opts {: width : height :row 1 :col 0
                         :relative :cursor :anchor :NW
                         :style :minimal : border : title :title_pos :center}
          win-set-opts {:winblend 90 :winhighlight "CursorLine:PmenuSel,NormalFloat:Pmenu"
                        :cursorline (not modifiable) :cursorlineopt :both}
          win (vim.api.nvim_open_win buf true win-open-opts)]
      (each [k v (pairs win-set-opts)]
        (vim.api.nvim_set_option_value k v {: win}))

      (fn close []
        (if modifiable (vim.cmd :stopinsert))
        (vim.api.nvim_win_close win true))

      (values buf close))))

{: get-range : get-selection : max : float-win}

