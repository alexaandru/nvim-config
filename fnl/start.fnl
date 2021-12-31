
;; fnlfmt: skip
(local {: !providers : !builtin : setup
        : au : lēt : opt : com : māp : sig : colo} (require :setup))

(local cfg (require :config))

;; fnlfmt: skip
(!builtin [:2html_plugin :man :matchit :tutor_mode_plugin
           :gzip :tarPlugin :zipPlugin])

(!providers [:python :python3 :node :ruby :perl])

(lēt cfg.vars)
(opt cfg.options)
(au cfg.autocmd)
(com cfg.commands)
(māp cfg.keys.global)
(sig cfg.signs)

;; fnlfmt: skip
(each [_ v (ipairs [:lsp :nvim-treesitter.configs :colorizer :package-info :dressing])]
  (setup v))

(colo :froggy)

