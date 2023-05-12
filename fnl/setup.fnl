(fn patch-pack [pack]
  (if (= (type pack) :string)
      (if (vim.startswith pack "https://") pack (.. "https://github.com/" pack))
      (do
        (set pack.src (patch-pack (. pack :src)))
        pack)))

(fn packadd [packs]
  (vim.pack.add (icollect [_ pack (ipairs packs)] (patch-pack pack))
                {:confirm false}))

;; fnlfmt: skip
(fn aug [name clear]
  (let [clear (if (= nil clear) true clear)]
    (vim.api.nvim_create_augroup name {: clear})))

(fn auc [group event cmd pb desc]
  (let [pattern (if (= (type pb) :string) pb)
        buffer (if (= (type pb) :number) pb)
        pattern (if (not (or pattern buffer)) "*" pattern)
        command (if (= (type cmd) :string) cmd)
        callback (if (= (type cmd) :function) cmd)
        opts {: group : callback : command : pattern : buffer : desc}]
    (assert (or command callback) "Either command or callback must be passed")
    (vim.api.nvim_create_autocmd event opts)))

(fn au [...]
  (each [name aux (pairs ...)]
    (let [group (aug name)]
      (each [_ params (ipairs aux)]
        (auc group (unpack params))))))

(fn com [...]
  (each [name cmd-or-args (pairs ...)]
    (var cmd cmd-or-args)
    (var args {})
    (when (= :table (type cmd))
      (set cmd cmd-or-args.cmd)
      (set cmd-or-args.cmd nil)
      (set args cmd-or-args))
    (if (= :string (type cmd))
        (let [cond-set (fn [pat arg val]
                         (if (> (vim.fn.match cmd pat) -1)
                             (if (= nil (. args arg)) (tset args arg val))))]
          (cond-set :<line1> :range "%")
          (cond-set :args> :nargs 1)
          (if (= nil args.bar)
              (set args.bar (= (vim.fn.match cmd "[^|]|[^|]") -1))))
        (when (= :function (type cmd))
          (set args.bar true)
          (set args.nargs "*")
          (set args.range "%")))
    (vim.api.nvim_create_user_command name cmd args)))

(fn opt [...]
  (each [k v (pairs ...)]
    (if (and (= (type v) :string) (vim.startswith v "+"))
        (do
          (set-forcibly! v (v:sub 2))
          (: (. vim.opt k) :append v))
        (and (= (type v) :table) (= (. v 1) :defaults))
        (: (. vim.opt k) :append (vim.list_slice v 2))
        (tset vim.opt k v))))

(fn lēt [cfg]
  (each [group vars (pairs cfg)]
    (each [k v (pairs vars)]
      (if (= (type v) :table)
          (each [kk vv (pairs v)]
            (tset (. vim group) (.. k "_" kk) vv))
          (tset (. vim group) k v)))))

(fn map [mappings]
  (each [mode mx (pairs mappings)]
    (each [_ m (ipairs mx)]
      (local (lhs rhs opts) (unpack m))
      (vim.keymap.set mode lhs rhs (or opts {})))))

(fn setup [...]
  (each [_ p (ipairs [...])]
    (let [setup (. (require p) :setup)
          (ok conf) (pcall require (.. :config. p))]
      (if ok (setup conf) (setup)))))

{:!providers #(vim.tbl_map #(tset vim.g (.. :loaded_ $ :_provider) 0) $)
 :!builtin #(vim.tbl_map #(tset vim.g (.. :loaded_ $) 1) $)
 : packadd : setup
 :r #(require (.. :config. $))
 :sig #(vim.tbl_map #(vim.cmd.sign (.. "define " $)) $)
 :colo #(vim.cmd.colorscheme $)
 : au : com : opt : lēt : map}
