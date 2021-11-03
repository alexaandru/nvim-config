(require :trim)
(require :util)

;; TODO: Watch
;; https://github.com/neovim/neovim/pull/9496
;; https://github.com/neovim/neovim/pull/15504
;; https://github.com/neovim/neovim/pull/14115
;; https://github.com/neovim/neovim/issues/14090 ; for breaking changes

;; fnlfmt: skip
(local {: !providers : !builtin : packadd : au : let-var : set-opt : com! : key-map : sig : colo}
       (require :setup))

;; fnlfmt: skip
(!builtin [:2html_plugin :gzip :man :matchit :!netrwPlugin :tarPlugin :tutor_mode_plugin :zipPlugin])
(!providers [:python :python3 :node :ruby :perl])

;; TODO: https://github.com/neovim/neovim/issues/12587 when resolved,
;; remove https://github.com/antoinemadec/FixCursorHold.nvim
;; (loaded from start not opt, hence not listed below)

;; fnlfmt: skip
(packadd [:nvim-lspconfig :nvim-lspupdate :lightbulb
          :nvim-treesitter :nvim-treesitter-textobjects
          :nvim-colorizer :nvim-notify :package-info :lsp_signature])

;(set vim.notify (require :notify))

(local cfg (require :config))

(let-var cfg.vars)
(set-opt cfg.options)
(au cfg.autocmd)
(com! cfg.commands)
(key-map cfg.keys.global)
(sig cfg.signs)
(colo :popping)

(let [{:setup setup-lsp} (require :lsp)
      {:setup setup-ts} (require :nvim-treesitter.configs)
      {:setup setup-colo} (require :colorizer)
      {:setup setup-pi} (require :package-info)]
  (setup-lsp)
  (setup-ts cfg.treesitter)
  (setup-colo)
  (setup-pi (require :config.package-info)))

;(vim.lsp.set_log_level :debug)

