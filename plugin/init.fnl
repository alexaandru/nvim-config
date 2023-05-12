(vim.loader.enable)

(local packs ["OXY2DEV/markview.nvim"
              "Saghen/blink.cmp"
              "alexaandru/fennel-nvim"
              "alexaandru/froggy"
              "alexaandru/site-util"
              "dstein64/vim-startuptime"
              "folke/snacks.nvim"
              "folke/which-key.nvim"
              "ibhagwan/fzf-lua"
              "lewis6991/gitsigns.nvim"
              "luukvbaal/statuscol.nvim"
              "nvim-lua/plenary.nvim"
              "nvim-tree/nvim-web-devicons"
              {:src "nvim-treesitter/nvim-treesitter"
               :version :main
               ;; TODO: implement pack update hooks
               :data {:after [":TSUpdate"]}}
              "nvim-treesitter/nvim-treesitter-context"
              {:src "nvim-treesitter/nvim-treesitter-textobjects"
               :version :main}
              "olimorris/codecompanion.nvim"
              "ravitemer/mcphub.nvim"
              "terrastruct/d2-vim"
              "windwp/nvim-ts-autotag"])

;; fnlfmt: skip
(local {: !providers : !builtin : setup : r : packadd
        : au : lēt : opt : com : map : colo} (require :setup))

(packadd packs)

(!providers [:python3 :node :ruby :perl])

;; fnlfmt: skip
(!builtin [:2html_plugin :man :matchit ;:netrwPlugin
           :tutor_mode_plugin :tarPlugin :zipPlugin])

(lēt (r :vars))
(opt (r :options))
(au {:Setup (r :autocmd)})
(com (r :commands))
(map (r :keys))

(setup :gitsigns :statuscol :nvim-web-devicons :codecompanion :blink.cmp
       :snacks :markview :mcphub)

;((. (require :fzf-lua) :register_ui_select))

(colo :challenge)
