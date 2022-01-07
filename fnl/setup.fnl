(local map vim.tbl_map)
(local cmd vim.cmd)

(fn all [cmds f]
  (fn [...]
    (map #(cmd (.. cmds " " (if f (f $) $))) (vim.tbl_flatten [...]))))

(local setup {:!providers #(map #(tset vim.g (.. :loaded_ $ :_provider) 0) $)
              :!builtin #(map #(tset vim.g (.. :loaded_ $) 1) $)
              :sig (all "sig define")
              :colo #(cmd (.. "colo " $))})

(fn setup.au [...]
  (each [name aux (pairs ...)]
    (cmd (: "aug %s | au!" :format name))
    ((all :au) aux)
    (cmd "aug END")))

(fn setup.com [...]
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
                  (set args.range "%")))
    (vim.api.nvim_add_user_command name cmd args)))

(fn setup.opt [...]
  (each [k v (pairs ...)]
    (if (and (= (type v) :string) (vim.startswith v "+"))
        (do
          (set-forcibly! v (v:sub 2))
          (: (. vim.opt k) :append v))
        (and (= (type v) :table) (= (. v 1) :defaults))
        (: (. vim.opt k) :append (vim.list_slice v 2))
        (tset vim.opt k v))))

(fn setup.lēt [cfg]
  (each [group vars (pairs cfg)]
    (each [k v (pairs vars)]
      (if (= (type v) :table)
          (each [kk vv (pairs v)]
            (tset (. vim group) (.. k "_" kk) vv))
          (tset (. vim group) k v)))))

(fn setup.māp [mappings]
  (each [mode mx (pairs mappings)]
    (each [_ m (ipairs mx)]
      (var (lhs rhs opts) (unpack m))
      (set opts (or opts {}))
      (vim.keymap.set mode lhs rhs opts))))

(fn setup.setup [package args]
  (let [config (require :config)]
    (if (and (not args) (. config package)) (set-forcibly! args package))
    (if args ((. (require package) :setup) (. config args))
        ((. (require package) :setup)))))

setup

