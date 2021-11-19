(let [{: !providers : !builtin} (require :setup)]
  (!providers [:python :python3 :node :ruby :perl])
  (!builtin [:2html_plugin :man :matchit :tutor_mode_plugin])
  (!builtin [:gzip :tarPlugin :zipPlugin]))

(let [{: au : lēt : opt : com : māp : sig : colo} (require :setup)
      cfg (require :config)]
  (lēt cfg.vars)
  (opt cfg.options)
  (au cfg.autocmd)
  (com cfg.commands)
  (māp cfg.keys.global)
  (sig cfg.signs)
  (colo :popping))

(let [{: setup-lsp} (require :lsp)
      {:setup setup-ts} (require :nvim-treesitter.configs)
      {:setup setup-colo} (require :colorizer)
      {:setup setup-pi} (require :package-info)]
  (setup-lsp)
  (setup-ts (. (require :config) :treesitter))
  (setup-colo)
  (setup-pi (require :config.package-info)))

