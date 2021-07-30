(local cfg (require :config))
(local lsp (require :lsp))
(local util (require :util))

(util.unpack_G [:GitStatus
                :CfgComplete
                :ProjRelativePath
                :Format
                :OrgImports
                :OrgJSImports
                :LspCapabilities
                :RunTests])

(util.disable_providers [:python :python3 :node :ruby :perl])

(util.disable_builtin [:2html_plugin
                       :gzip
                       :man
                       :matchit
                       :netrwPlugin
                       :tarPlugin
                       :tutor_mode_plugin
                       :zipPlugin])

;; TODO: https://github.com/neovim/neovim/issues/12587 when resolved,
;; remove https://github.com/antoinemadec/FixCursorHold.nvim
;; (loaded from start not opt, hence not listed below)
(util.packadd [:nvim-lspconfig
               :nvim-lspupdate
               :nvim-treesitter
               :nvim-treesitter-textobjects
               :nvim-colorizer
               :lsp_signature])

(util.let cfg.vars)

(lsp.setup)

(let [ts (require :nvim-treesitter.configs)]
  (ts.setup cfg.treesitter))

(util.set cfg.options)

(util.au cfg.autocmd)

((. (require :colorizer) :setup))

(util.com cfg.commands)

(util.map cfg.keys.global)

(util.sig cfg.signs)

(util.setup_notify)

(util.colo :froggy)

