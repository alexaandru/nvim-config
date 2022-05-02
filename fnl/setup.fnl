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
    (match (type cmd)
      :string (let [cond-set (fn [pat arg val]
                               (if (> (vim.fn.match cmd pat) -1)
                                   (if (= nil (. args arg)) (tset args arg val))))]
                (cond-set :<line1> :range "%")
                (cond-set :args> :nargs 1)
                (if (= nil args.bar)
                    (set args.bar (= (vim.fn.match cmd "[^|]|[^|]") -1))))
      :function (do
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
      (var (lhs rhs opts) (unpack m))
      (set opts (or opts {}))
      (vim.keymap.set mode lhs rhs opts))))

(fn setup [package args]
  (let [config (require :config)]
    (if (and (not args) (. config package)) (set-forcibly! args package))
    (if args ((. (require package) :setup) (. config args))
        ((. (require package) :setup)))))

{:!providers #(vim.tbl_map #(tset vim.g (.. :loaded_ $ :_provider) 0) $)
 :!builtin #(vim.tbl_map #(tset vim.g (.. :loaded_ $) 1) $)
 : setup
 :sig #(vim.tbl_map #(vim.cmd (.. "sig define " $)) $)
 :colo #(vim.cmd (.. "colo " $))
 : au
 : com
 : opt
 : lēt
 : map}

