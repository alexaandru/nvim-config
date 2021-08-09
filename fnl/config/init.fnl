(let [configs [:autocmd :commands :keys :options :signs :treesitter :vars]]
  (collect [_ v (ipairs configs)]
    (values v (require (.. :config. v)))))

