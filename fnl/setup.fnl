(local map vim.tbl_map)
(local cmd vim.cmd)

(fn all [cmds f]
  (fn [...]
    (map #(cmd (.. cmds " " (if f (f $) $))) (vim.tbl_flatten [...]))))

(fn ins [t v]
  (table.insert t v)
  t)

;; COMmands (as in vim commands) PREprocessor.
;;
;; It understand the following, tiny DSL: when c(ommand) is prefixed
;; with one of the following characters, it will replace them with
;; the corresponding argument:
;;
;; |  -bar
;; %  -range=%
;; =n -nargs=n ; where n ∈ {1,2,...,*}
;;
;; (or any of their combinations, i.e. |=4% would be replaced with
;;  -bar -nargs=4 -range=%).
(fn com-pre [c opts]
  (set-forcibly! opts (or opts []))
  (match (c:sub 1 1)
    "|" (com-pre (c:sub 2) (ins opts :-bar))
    "%" (com-pre (c:sub 2) (ins opts "-range=%"))
    "=" (com-pre (c:sub 3) (ins opts (.. :-nargs= (c:sub 2 2))))
    _ (vim.fn.join (vim.tbl_flatten [opts c]))))

(local setup {:packadd (all :pa)
              :!providers #(map #(tset vim.g (.. :loaded_ $ :_provider) 0) $)
              :!builtin #(map #(tset vim.g (.. :loaded_ $) 1) $)
              ;; TODO: https://github.com/neovim/neovim/issues/9876
              :sig (all "sig define")
              ;; TODO: https://github.com/neovim/neovim/pull/11613
              :com! (all :com! com-pre)
              :colo #(cmd (.. "colo " $))})

;; TODO: https://github.com/neovim/neovim/pull/14661
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

