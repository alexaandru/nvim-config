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
              {:src :ravsii/tree-sitter-d2
               :version :main
               :data {:build "make nvim-install"}}
              :rose-pine/neovim
              :windwp/nvim-ts-autotag])

(local pack-confs
       {:rose-pine {:styles {:bold true :italic true :transparency true}}
        :markview {:preview {:icon_provider :devicons
                             :filetypes [:markdown :codecompanion]
                             :ignore_buftypes []}
                   :experimental {:check_rtp_message false}}})

; Setup attempts to locate a setup function in each package.
; If it exists, it will be called (with an optional config from pack-confs).
(fn setup [packs]
  (each [_ p (ipairs packs)]
    (let [name (if (= (type p) :string) p (. p :src))
          name (vim.fn.fnamemodify name ":t")
          name (vim.fn.substitute name "\\.nvim$" "" "")
          (ok pack) (pcall require name)]
      (if ok (let [setup (if (= (type pack) :table) (. pack :setup))
                   setup (if (= (type setup) :function) setup)
                   conf (?. pack-confs name)]
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
  (let [name event.data.spec.name
        dir event.data.path
        spec (: (vim.iter packs) :find
                #(let [name (if (= (type $) :string) $ (. $ :src))
                       name (vim.fn.fnamemodify name ":t")]
                   (= name name)))
        build (?. spec :data :build)
        after (?. spec :data :after)]
    (if build
        (let [cmd (.. "cd " (vim.fn.shellescape dir) " && " build)
              out (vim.fn.system cmd)
              fy vim.notify]
          (if (= vim.v.shell_error 0)
              (fy (.. "Build succeeded for " event.data.spec.name)
                  vim.log.levels.INFO)
              (fy (.. "Build failed for " event.data.spec.name ": " out)
                  vim.log.levels.ERROR))))
    (if after
        (let [wait-for-pkg (fn wait []
                             (tset package.loaded name nil)
                             (let [(ok _) (pcall require name)]
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
