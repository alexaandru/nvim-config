;; Quick check: #ff0000 #00ff00 #0000ff
;; #f00 #0f0 #00f #00f00f #f00f00 #0f00f0
(local colorized {})

(fn fg-color [word]
  (let [sum (accumulate [sum 0 _ n (ipairs [1 3 5])]
              (+ sum (tonumber (word:sub n (+ n 1)) 16)))]
    (if (< (/ sum 3) 78) "#ffffff" "#000000")))

(fn remember [word] ; https://github.com/neovim/neovim/issues/12544
  (let [tmp (or vim.w.colorized {})]
    (tset tmp word true)
    (set vim.w.colorized tmp)))

(fn colorize-word [word matchstr]
  (set-forcibly! matchstr (or matchstr word))
  (let [group (.. :Colorize_ word)
        fg (fg-color word)]
    (when (not (. colorized word))
      (vim.api.nvim_set_hl 0 group {:bg (.. "#" word) : fg})
      (tset colorized word true))
    (when (not (?. vim.w.colorized matchstr))
      (vim.fn.matchadd group (.. "\\c#" matchstr))
      (remember matchstr))))

(fn hex3-to-hex6 [word]
  (accumulate [out "" i (ipairs [1 1 1])]
    (let [s (word:sub i i)] (.. out s s))))

(fn normalize [word]
  (let [word (word:upper)]
    (if (= 3 (length word)) (hex3-to-hex6 word) word)))

(fn colorize-iter [iter]
  (let [word (iter)]
    (when word
      (colorize-word (normalize word) (word:upper))
      (colorize-iter iter))))

(fn colorize-line [line]
  ;; TODO: either find a way to NOT colorize groups of 3 inside groups of 6
  ;; or drop it permanently.
  (each [_ pat (ipairs ["#(%x%x%x%x%x%x)" "#(__%x%x%x)[%X\\n]"])]
    (colorize-iter (line:gmatch pat))))

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
  (vim.api.nvim_create_autocmd [:WinNew :BufEnter] {: group : callback : pattern})
  (vim.api.nvim_create_autocmd [:TextChanged :TextChangedI] {: group :callback text-changed : pattern}))

