(local colorized {})

(fn fg-color [word]
  (let [sum (accumulate [sum 0 _ n (ipairs [1 3 5])]
              (+ sum (tonumber (word:sub n (+ n 1)) 16)))]
    (if (< (/ sum 3) 128) "#ffffff" "#000000")))

(fn remember [word]
  ;; FIXME: why is this needed??
  ;; Setting directly via tset() does not work...
  (let [tmp (or vim.w.colorized {})]
    (tset tmp word true)
    (set vim.w.colorized tmp)))

(fn colorize-word [word]
  (let [group (.. :Colorize_ word)
        fg (fg-color word)]
    (when (not (. colorized word))
      (vim.api.nvim_set_hl 0 group {:bg (.. "#" word) : fg})
      (tset colorized word true))
    (when (not (?. vim.w.colorized word))
      (vim.fn.matchadd group (.. "\\c#" word))
      (remember word))))

(fn colorize-iter [iter]
  (let [word (iter)]
    (when word
      (colorize-word (word:upper))
      (colorize-iter iter))))

(fn colorize-line [line]
  (colorize-iter (line:gmatch "#(%x%x%x%x%x%x)")))

(fn colorize-buf [buf line]
  (set-forcibly! line (or line 0))
  (let [step 100
        lines (vim.api.nvim_buf_get_lines buf line (+ line step) false)]
    (colorize-line (table.concat lines " "))
    (if (> (length lines) 0) (colorize-buf buf (+ line step)))))

(fn text-changed []
  (colorize-line (vim.fn.getline (vim.fn.line "."))))

(let [group (vim.api.nvim_create_augroup :Colorizer {:clear true})
      callback #(colorize-buf $.buf)
      pattern "*"]
  (vim.api.nvim_create_autocmd [:WinNew :BufEnter]
                               {: group : callback : pattern})
  (vim.api.nvim_create_autocmd [:TextChanged :TextChangedI]
                               {: group :callback text-changed : pattern}))

