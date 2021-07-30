(local cfg {})

(each [_ v (ipairs [:autocmd :commands :keys :options :signs :treesitter :vars])]
  (tset cfg v (require (.. :config. v))))

cfg

