(collect [_ v (ipairs [:autocmd :commands :keys :options :signs :treesitter :vars])]
  (values (if (= v :treesitter) :nvim-treesitter.configs v) (require (.. :config. v))))

