(local map vim.tbl_map)
(local cmd vim.cmd)

(fn all [cmds]
  (fn [...]
    (map #(cmd (.. cmds " " $)) (vim.tbl_flatten [...]))))

(local setup {:packadd (all :pa)
              :!providers #(map #(tset vim.g (.. :loaded_ $ :_provider) 0) $)
              :!builtin #(map #(tset vim.g (.. :loaded_ $) 1) $)
              ;; TODO: https://github.com/neovim/neovim/issues/9876
              :sig (all "sig define")
              ;; TODO: https://github.com/neovim/neovim/pull/11613
              :com! (all :com!)
              :colo #(cmd (.. "colo " $))})

;; TODO: https://github.com/neovim/neovim/pull/12378
;;       https://github.com/neovim/neovim/pull/14661
(fn setup.au [...]
  (each [name aux (pairs ...)]
    (cmd (: "aug %s | au!" :format name))
    ((all :au) aux)
    (cmd "aug END")))

(fn setup.set-opt [...]
  (each [k v (pairs ...)]
    (if (and (= (type v) :string) (vim.startswith v "+"))
        (do
          (set-forcibly! v (v:sub 2))
          (: (. vim.opt k) :append v))
        (and (= (type v) :table) (= (. v 1) :defaults))
        (: (. vim.opt k) :append (vim.list_slice v 2))
        (tset vim.opt k v))))

(fn setup.let-var [cfg]
  (each [group vars (pairs cfg)]
    (each [k v (pairs vars)]
      (if (= (type v) :table)
          (each [kk vv (pairs v)]
            (tset (. vim group) (.. k "_" kk) vv))
          (tset (. vim group) k v)))))

(fn setup.key-map [mappings]
  (each [mode mx (pairs mappings)]
    (each [_ m (ipairs mx)]
      (var (lhs rhs opts) (unpack m))
      (set opts (or opts {}))
      (set opts.noremap true)
      (vim.api.nvim_set_keymap mode lhs rhs opts))))

(fn setup.lightbulb []
  (let [{: update_lightbulb} (require :nvim-lightbulb)]
    (update_lightbulb {:sign {:enabled false}
                       :virtual_text {:enabled true :text "💡"}})))

setup

