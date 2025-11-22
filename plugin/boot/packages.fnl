(local packs [:OXY2DEV/markview.nvim
              :alexaandru/site-util
              :folke/sidekick.nvim
              :lewis6991/gitsigns.nvim
              :nvim-tree/nvim-web-devicons
              {:src :nvim-treesitter/nvim-treesitter
               :version :main
               :data {:after :TSUpdate}}
              :nvim-treesitter/nvim-treesitter-context
              {:src :nvim-treesitter/nvim-treesitter-textobjects
               :version :main}
              :ravsii/tree-sitter-d2
              :rose-pine/neovim
              :windwp/nvim-ts-autotag])

(local pack-configs
       {:rose-pine {:styles {:bold true :italic true :transparency true}}
        :markview {:preview {:icon_provider :devicons
                             :filetypes [:markdown :codecompanion]
                             :ignore_buftypes []}
                   :experimental {:check_rtp_message false}}})

; Setup attempts to locate a setup function in each package.
; If it exists, it will be called (with an optional config from pack-configs map).
(fn setup [packs]
  (each [_ p (ipairs packs)]
    (let [name (if (= (type p) :string) p (. p :src))
          name (vim.fn.fnamemodify name ":t")
          name (vim.fn.substitute name "\\.nvim$" "" "")
          (ok pack) (pcall require name)]
      (if ok (let [setup (if (= (type pack) :table) (. pack :setup))
                   setup (if (= (type setup) :function) setup)
                   conf (?. pack-configs name)]
               (if setup (if conf (setup conf) (setup))))))))

(fn patch-pack [pack]
  (if (= (type pack) :string)
      (if (vim.startswith pack "https://") pack (.. "https://github.com/" pack))
      (do
        (set pack.src (patch-pack (. pack :src)))
        pack)))

; Loads plugins and attempts to call setup() for each.
(fn pack-add [packs opts]
  (set-forcibly! opts {:confirm false})
  (vim.pack.add (icollect [_ pack (ipairs packs)] (patch-pack pack)) opts)
  (setup packs))

; Hook to be called after a package is changed.
(fn pack-changed [event]
  (let [after (?. event.data.spec.data :after)]
    (if after
        (let [pkg-name event.data.spec.name
              wait-for-pkg (fn wait []
                             (tset package.loaded pkg-name nil)
                             (let [(ok _) (pcall require pkg-name)]
                               (if ok
                                   (if (= (type after) :string) (vim.cmd after)
                                       (= (type after) :function) (after)
                                       nil)
                                   (vim.defer_fn wait 50))))]
          (wait-for-pkg))))
  false)

(let [au vim.api.nvim_create_autocmd
      group (vim.api.nvim_create_augroup :PackSetup {:clear true})]
  (au :PackChanged {: group :callback pack-changed})
  (pack-add packs))

; Place any code that should run after plugins are loaded here.
(vim.cmd.colorscheme :rose-pine)
