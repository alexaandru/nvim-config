(local map vim.tbl_map)

(fn all [cmd]
  (fn [...]
    (map #(vim.cmd (.. cmd " " $)) (vim.tbl_flatten [...]))))

(local util {:sig (all "sig define")
             :packadd (all :pa)
             ;; TODO: https://github.com/neovim/neovim/pull/11613
             :com (all :com!)
             :colo (all :colo)
             ;; TODO: https://github.com/neovim/neovim/issues/9876
             :hi (all :hi!)})

(local wait-default 2000)

(fn util.Fenval []
  (fn setline [job data name]
    (local result (. data 1))
    (if (not= result "")
        (vim.fn.setline "." (.. (vim.fn.getline ".") " ;; => " result))))

  (local line (vim.fn.getline "."))
  (local job (vim.fn.jobstart "fennel -" {:on_stdout setline}))
  (vim.fn.chansend job (.. "(print " line ")"))
  (vim.fn.chanclose job :stdin))

(fn util.Format [wait-ms]
  (vim.lsp.buf.formatting_sync nil (or wait-ms wait-default)))

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
       (let [c (vim.fn.stdpath :config)]
         (map #(string.sub $ (+ (length c) 2))
              (vim.fn.glob (.. c "/" :fnl/**/*.fnl) 0 1))))

(fn util.CfgComplete [arg-lead]
  (vim.tbl_filter #(or (= arg-lead "") ($:find arg-lead)) cfg-files))

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
  (print (vim.inspect (collect [_ c (pairs (vim.lsp.buf_get_clients))]
                        (values c.name
                                (collect [k v (pairs c.resolved_capabilities)]
                                  (if v (values k v))))))))

(fn util.RunTests []
  (vim.cmd :echo)
  (var curr-fn ((. (require :nvim-treesitter) :statusline)))
  (if (not (vim.startswith curr-fn "func ")) (set curr-fn "*")
      (set curr-fn (curr-fn:sub 6 (- (curr-fn:find "%(") 1))))
  (vim.lsp.buf.execute_command {:arguments [{:URI (vim.uri_from_bufnr 0)
                                             :Tests {1 curr-fn}}]
                                :command :gopls.run_tests}))

(fn util.unpack [...]
  (unpack (collect [_ v (ipairs vim.tbl_flatten [...])]
            (. util v))))

(fn util.unpack_G [...]
  (map #(tset _G $ (. util $)) (vim.tbl_flatten [...])))

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
  (map #(tset vim.g (.. :loaded_ $ :_provider) 0) px))

(fn util.disable_builtin [px]
  (map #(tset vim.g (.. :loaded_ $) 1) px))

(fn util.let [cfg]
  (each [group vars (pairs cfg)]
    (each [k v (pairs vars)]
      (if (= (type v) :table)
          (each [kk vv (pairs v)]
            (tset (. vim group) (.. k "_" kk) vv))
          (tset (. vim group) k v)))))

util

