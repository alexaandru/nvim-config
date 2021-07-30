(fn all [cmd]
  (fn [...]
    (local args (vim.tbl_flatten [...]))
    (each [_ v (ipairs args)]
      (vim.cmd (.. cmd " " v)))))

(local util {:sig (all "sig define")
             :packadd (all :pa)
             ;; TODO: https://github.com/neovim/neovim/pull/11613
             :com (all :com!)
             :colo (all :colo)
             ;; TODO: https://github.com/neovim/neovim/issues/9876
             :hi (all :hi!)})

(local icons {vim.log.levels.TRACE :zoom-in
              vim.log.levels.INFO :information
              vim.log.levels.WARN :warning
              vim.log.levels.ERROR :error
              vim.log.levels.DEBUG :applications-debugging})

(local wait-default 2000)

(fn util.SynStack []
  (let [out {}]
    (each [id (ipairs (vim.fn.synstack (vim.fn.line ".") (vim.fn.col ".")))]
      (tset out (+ (length out) 1) (vim.fn.synIDattr id :name)))
    out))

(fn util.Format [wait-ms]
  (set-forcibly! wait-ms (or wait-ms wait-default))
  (vim.lsp.buf.formatting_sync nil wait-ms))

;; Synchronously organise imports, courtesy of
;; https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-656372575 and
;; https://github.com/lucax88x/configs/blob/master/dotfiles/.config/nvim/lua/lt/lsp/functions.lua
(fn util.OrgImports [wait-ms]
  (set-forcibly! wait-ms (or wait-ms wait-default))
  (local params (vim.lsp.util.make_range_params))
  (set params.context {:only [:source.organizeImports]})
  (local result (vim.lsp.buf_request_sync 0 :textDocument/codeAction params
                                          wait-ms))
  (each [_ res (pairs (or result {}))]
    (each [_ r (pairs (or res.result {}))]
      (if r.edit (vim.lsp.util.apply_workspace_edit r.edit)
          (vim.lsp.buf.execute_command r.command)))))

(fn util.OrgJSImports []
  (vim.lsp.buf.execute_command {:arguments [(vim.fn.expand "%:p")]
                                :command :_typescript.organizeImports}))

;; inspired by https://vim.fandom.com/wiki/Smart_mapping_for_tab_completion
(fn util.SmartTabComplete []
  (local s (: (: (vim.fn.getline ".") :sub 1 (- (vim.fn.col ".") 1)) :gsub
              "%s+" ""))

  (fn t [str]
    (vim.api.nvim_replace_termcodes str true true true))

  (var out (t :<C-x><C-o>))
  (when (= s "")
    (set out (t :<Tab>)))
  (when (= (s:sub (s:len) (s:len)) "/")
    (set out (t :<C-x><C-f>)))
  out)

(local cfg-files
       (do
         (local pat :fnl/**/*.fnl)
         (local c (vim.fn.stdpath :config))

         (fn f [v]
           (string.sub v (+ (length c) 2)))

         (vim.tbl_map f (vim.fn.glob (.. c "/" pat) 0 1))))

(fn util.CfgComplete [arg-lead]
  (fn f [v]
    (or (= arg-lead "") (v:find arg-lead)))

  (vim.tbl_filter f cfg-files))

(fn util.GitStatus []
  (let [branch (vim.trim (vim.fn.system "git rev-parse --abbrev-ref HEAD 2> /dev/null"))]
    (when (= branch "")
      (lua "return "))
    (local dirty
           (.. (vim.fn.system "git diff --quiet || echo -n \\*")
               (vim.fn.system "git diff --cached --quiet || echo -n \\+")))
    (set vim.w.git_status (.. branch dirty))))

(fn util.ProjRelativePath []
  (string.sub (vim.fn.expand "%:p") (+ (length vim.w.proj_root) 1)))

(fn util.LspCapabilities []
  (let [cap {}]
    (each [_ c (pairs (vim.lsp.buf_get_clients))]
      (tset cap c.name c.resolved_capabilities))
    (print (vim.inspect cap))))

(fn util.RunTests []
  (vim.cmd :echo)
  (var curr-fn ((. (require :nvim-treesitter) :statusline)))
  (if (not (vim.startswith curr-fn "func ")) (set curr-fn "*")
      (set curr-fn (curr-fn:sub 6 (- (curr-fn:find "%(") 1))))
  (vim.lsp.buf.execute_command {:arguments [{:URI (vim.uri_from_bufnr 0)
                                             :Tests {1 curr-fn}}]
                                :command :gopls.run_tests}))

(fn util.unpack [...]
  (let [arg (vim.tbl_flatten [...])
        what []]
    (each [_ v (ipairs arg)]
      (table.insert what (. util v)))
    (unpack what)))

(fn util.unpack_G [...]
  (let [arg (vim.tbl_flatten [...])]
    (each [_ v (ipairs arg)]
      (tset _G v (. util v)))))

(fn util.setup_notify []
  (let [orig-notify vim.notify]
    (set vim.notify (fn [msg log-level]
                      (do
                        (set-forcibly! log-level
                                       (or log-level vim.log.levels.INFO))
                        (local icon (. icons log-level))
                        (orig-notify msg log-level)
                        (vim.fn.jobstart [:notify-send
                                          :-i
                                          (.. :dialog- icon)
                                          msg]))))))

;; TODO: https://github.com/neovim/neovim/pull/12378
(fn util.au [...]
  (each [name au (pairs ...)]
    (vim.cmd (: "aug %s | au!" :format name))
    ((all :au) au)
    (vim.cmd "aug END")))

(fn util.set [...]
  (each [k v (pairs ...)]
    (if (and (= (type v) :string) (vim.startswith v "+"))
        (do
          (set-forcibly! v (v:sub 2))
          (: (. vim.opt k) :append v))
        (and (= (type v) :table) (= (. v 1) :defaults))
        (: (. vim.opt k) :append (vim.list_slice v 2))
        (tset vim.opt k v))))

(fn util.map [mappings]
  (each [mode mx (pairs mappings)]
    (each [_ m (ipairs mx)]
      (var (lhs rhs opts) (unpack m))
      (set opts (or opts {}))
      (set opts.noremap true)
      (vim.api.nvim_set_keymap mode lhs rhs opts))))

(fn util.disable_providers [px]
  (fn f [p]
    (tset vim.g (.. :loaded_ p :_provider) 0))

  (vim.tbl_map f px))

(fn util.disable_builtin [plugins]
  (each [_ v (ipairs plugins)]
    (tset vim.g (.. :loaded_ v) 1)))

(fn util.let [cfg]
  (each [group vars (pairs cfg)]
    (each [k v (pairs vars)]
      (if (= (type v) :table)
          (each [kk vv (pairs v)]
            (tset (. vim group) (.. k "_" kk) vv))
          (tset (. vim group) k v)))))

util

