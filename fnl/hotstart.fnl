(require :trim)
(require :util)

;; fnlfmt: skip
(local {: disable-providers : disable-builtin : packadd : au : le : se : com : kmap : sig : colo} (require :setup))
(local cfg (require :config))
(local lsp (require :lsp))

;; fnlfmt: skip
(disable-builtin [:2html_plugin :gzip :man :matchit :netrwPlugin :tarPlugin :tutor_mode_plugin :zipPlugin])
(disable-providers [:python :python3 :node :ruby :perl])

;; TODO: https://github.com/neovim/neovim/issues/12587 when resolved,
;; remove https://github.com/antoinemadec/FixCursorHold.nvim
;; (loaded from start not opt, hence not listed below)

;; fnlfmt: skip
(packadd [:nvim-lspconfig :nvim-lspupdate
          :nvim-treesitter :nvim-treesitter-textobjects
          :nvim-colorizer :nvim-notify :package-info :lsp_signature])

(set vim.notify (require :notify))

(let [{: setup} (require :package-info)]
  (setup (require :config.package-info)))

(le cfg.vars)

(lsp.setup)
(let [{: setup} (require :nvim-treesitter.configs)]
  (setup cfg.treesitter))

(se cfg.options)
(au cfg.autocmd)
(com cfg.commands)
(kmap cfg.keys.global)
(sig cfg.signs)
(colo :froggy)

(let [{: setup} (require :colorizer)]
  (setup))

;(vim.lsp.set_log_level :debug)

