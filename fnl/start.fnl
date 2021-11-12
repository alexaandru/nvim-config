
;; fnlfmt: skip
(let [{: !providers : !builtin} (require :setup)]
  (!builtin   [:2html_plugin :gzip :man :matchit :!netrwPlugin
               :tarPlugin :tutor_mode_plugin :zipPlugin])
  (!providers [:python :python3 :node :ruby :perl]))

;(set vim.notify (require :notify))
;(vim.lsp.set_log_level :debug)

(let [{: au : lēt : opt : com : māp : sig : colo} (require :setup)
      cfg (require :config)]
  (lēt cfg.vars)
  (opt cfg.options)
  (au cfg.autocmd)
  (com cfg.commands)
  (māp cfg.keys.global)
  (sig cfg.signs)
  (colo :popping)
  ;; setup
  (let [{:setup setup-lsp} (require :lsp)
        {:setup setup-ts} (require :nvim-treesitter.configs)
        {:setup setup-colo} (require :colorizer)
        {:setup setup-pi} (require :package-info)]
    (setup-lsp)
    (setup-ts cfg.treesitter)
    (setup-colo)
    (setup-pi (require :config.package-info))))

