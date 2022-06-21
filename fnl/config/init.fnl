(collect [_ v (ipairs [:autocmd :commands :keys :options :signs :treesitter :tsserver :vars])]
  (values (if (= v :treesitter) :nvim-treesitter.configs v) (require (.. :config. v))))

