(fn patch-pack [pack]
  (let [pack (if (= (type pack) :string) {:src pack} pack)
        src (. pack :src)
        src (if (vim.startswith src "https://") src
                (.. "https://github.com/" src))
        name (or (. pack :name) (vim.fn.fnamemodify src ":t"))
        name (vim.fn.substitute name :.nvim$ "" "")]
    (doto pack
      (tset :src src)
      (tset :name name))))

(local packs
       [{:src :OXY2DEV/markview.nvim
         :data {:conf {:preview {:icon_provider :devicons
                                 :filetypes [:markdown :codecompanion]
                                 :ignore_buftypes []}
                       :experimental {:check_rtp_message false}}}}
        {:src :alexaandru/site-util :name :site.util}
        :folke/sidekick.nvim
        {:src :lewis6991/gitsigns.nvim
         :data {:conf (fn [] {:on_attach (require :gitsigns_conf)})}}
        :nvim-tree/nvim-web-devicons
        {:src :nvim-treesitter/nvim-treesitter
         :version :main
         :data {:after :TSUpdate}}
        {:src :nvim-treesitter/nvim-treesitter-context
         :name :treesitter-context
         :data {:conf {:max_lines 5 :trim_scope :inner}}}
        {:src :nvim-treesitter/nvim-treesitter-textobjects :version :main}
        {:src :ravsii/tree-sitter-d2
         :version :main
         :data {:build "make nvim-install"}}
        {:src :rose-pine/neovim
         :name :rose-pine
         :data {:conf {:styles {:bold true :italic true :transparency true}}}}
        {:src :windwp/nvim-ts-autotag
         :data {:conf {:opts {:enable_close_on_slash true}}}}])

;; Standardize pack definitions.
(each [i p (ipairs packs)]
  (tset packs i (patch-pack p)))

; Hook to be called after a package is changed.
(fn pack-changed [event]
  (let [name event.data.spec.name
        dir event.data.path
        spec (: (vim.iter packs) :find #(= (. $ :name) name))
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

; Setup attempts to locate a setup function in each package.
; If it exists, it will be called (with an optional config from pack data).
(fn setup [packs]
  (each [_ p (ipairs packs)]
    (let [name (. p :name)
          (ok pack) (pcall require name)]
      (if ok (let [setup (if (= (type pack) :table) (. pack :setup))
                   setup (if (= (type setup) :function) setup)
                   conf (?. p :data :conf)
                   conf (if (= (type conf) :function) (conf))]
               (if setup (if conf (setup conf) (setup))))
          (vim.notify (.. "Package not found " name "; will not call setup()")
                      vim.log.levels.INFO)))))

(let [au vim.api.nvim_create_autocmd
      group (vim.api.nvim_create_augroup :PackSetup {:clear true})]
  (au :PackChanged {: group :callback pack-changed})
  (vim.pack.add packs {:confirm false})
  (setup packs))
