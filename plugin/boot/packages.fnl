(local packs
       [{:src :OXY2DEV/markview.nvim
         :data {:conf {:preview {:icon_provider :mini
                                 :filetypes [:markdown :nvim-pack]}}}}
        {:src :alexaandru/site-util :name :site.util}
        {:src :folke/sidekick.nvim
         :data {:conf {:cli {:win {:layout :bottom}
                             :mux {:enabled true :backend :zellij}
                             :tools {:amp (require :amp-conf)}}}}}
        :lewis6991/gitsigns.nvim
        :nvim-mini/mini.icons
        {:src :nvim-treesitter/nvim-treesitter
         :version :main
         :data {:after :TSUpdate}}
        {:src :nvim-treesitter/nvim-treesitter-context
         :name :treesitter-context
         :data {:conf {:max_lines 5 :trim_scope :inner}}}
        {:src :nvim-treesitter/nvim-treesitter-textobjects
         :version :main
         :data {:conf {:select {:lookahead true}}}}
        {:src :ravsii/tree-sitter-d2
         :version :main
         :data {:build "make nvim-install"}}
        {:src :windwp/nvim-ts-autotag
         :data {:conf {:opts {:enable_close_on_slash true}}}}])

(fn patch-pack [pack]
  (let [pack (if (= (type pack) :string) {:src pack} pack)
        https "https://"
        src (. pack :src)
        src (if (vim.startswith src https) src (.. https "github.com/" src))
        name (or (. pack :name) (vim.fn.fnamemodify src ":t"))
        name (name:gsub :.nvim$ "")]
    (doto pack
      (tset :src src)
      (tset :name name))))

; Standardize pack definitions.
(each [i p (ipairs packs)]
  (tset packs i (patch-pack p)))

; Hook to be called after a package is changed.
(fn pack-changed [event]
  (let [name event.data.spec.name
        dir event.data.path
        packs (vim.iter packs)
        spec (packs:find #(= $.name name))
        build (?. spec :data :build)
        after (?. spec :data :after)]
    (if build
        ((fn wait []
           (if (= (vim.fn.isdirectory dir) 1)
               (let [cmd (.. "cd " (vim.fn.shellescape dir) " && " build)
                     out (vim.fn.system cmd)
                     fy vim.notify]
                 (if (= vim.v.shell_error 0)
                     (fy (.. "Build succeeded for " event.data.spec.name)
                         vim.log.levels.INFO)
                     (fy (.. "Build failed for " event.data.spec.name ": " out)
                         vim.log.levels.ERROR)))
               (vim.defer_fn wait 50)))))
    (if after
        ((fn wait []
           (tset package.loaded name nil)
           (let [(ok _) (pcall require name)]
             (if ok
                 (if (= (type after) :string) (vim.cmd after)
                     (= (type after) :function) (after)
                     nil)
                 (vim.defer_fn wait 50))))))
    false))

; Setup attempts to locate a setup function in each package.
; If it exists, it will be called (with an optional config from pack data).
(fn setup [packs]
  (each [_ p (ipairs packs)]
    (let [name (. p :name)
          (ok pack) (pcall require name)]
      (if ok (let [setup (if (= (type pack) :table) (. pack :setup))
                   setup (if (= (type setup) :function) setup)
                   conf (?. p :data :conf)
                   conf (if (= (type conf) :function) (conf) conf)]
               (if setup (if conf (setup conf) (setup))))
          (vim.notify (.. "Package not found " name "; cannot call setup()")
                      vim.log.levels.INFO)))))

(let [au vim.api.nvim_create_autocmd
      group (vim.api.nvim_create_augroup :PackSetup {:clear true})]
  (au :PackChanged {: group :callback pack-changed})
  (doto packs
    (vim.pack.add {:confirm false})
    (setup)))

(vim.treesitter.language.register :markdown :nvim-pack)
