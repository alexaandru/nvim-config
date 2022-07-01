(collect [_ v (ipairs [:autocmd :commands :dressing :keys :options :signs :treesitter :tsserver :vars])]
  (if (= v :treesitter) :nvim-treesitter.configs v) (require (.. :config. v)))

