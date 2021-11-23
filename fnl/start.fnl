(local {: !providers : !builtin : setup
        : au : lēt : opt : com : māp : sig : colo} (require :setup))
(local cfg (require :config))

(!providers [:python :python3 :node :ruby :perl])
(!builtin [:2html_plugin :man :matchit :tutor_mode_plugin :gzip :tarPlugin :zipPlugin])

(lēt cfg.vars)
(opt cfg.options)
(au cfg.autocmd)
(com cfg.commands)
(māp cfg.keys.global)
(sig cfg.signs)

(colo :froggy)

(setup :lsp)
(setup :nvim-treesitter.configs)
(setup :colorizer)
(setup :package-info)
