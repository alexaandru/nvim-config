;; fnlfmt: skip
(collect [_ v (ipairs [:autocmd :commands :keys :options :signs :treesitter :vars])]
  (values v (require (.. :config. v))))

