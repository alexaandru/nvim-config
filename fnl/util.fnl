(local map vim.tbl_map)
(local cmd vim.cmd)

(fn all [cmds]
  (fn [...]
    (map #(cmd (.. cmds " " $)) (vim.tbl_flatten [...]))))

(local util {:sig (all "sig define")
             ;; TODO: https://github.com/neovim/neovim/pull/11613
             :com (all :com!)
             :colo (all :colo)
             ;; TODO: https://github.com/neovim/neovim/issues/9876
             :hi (all :hi!)})

(local wait-default 2000)

(fn _G.DisableProviders [px]
  (map #(tset vim.g (.. :loaded_ $ :_provider) 0) px))

(fn _G.DisableBuiltin [px]
  (map #(tset vim.g (.. :loaded_ $) 1) px))

(fn _G.packadd [px]
  ((all :pa) px))

(fn _G.FnlEval [start stop]
  (if (= vim.bo.filetype :fennel)
      ;; WIP ... can't get it to detect mode yet...
      ;(let [comp-fn (if (= (vim.fn.mode) :n) :compile-buffer :compile-selection)
      ;      (ok code) ((. (require :hotpot.api.compile) comp-fn) 0)]
      (let [(any) ((. (require :hotpot.api.eval) :eval-range) 0 start stop)]
        (_G.FnlDo true (vim.inspect any) true))))

(fn _G.FnlCompile [start stop]
  (if (= vim.bo.filetype :fennel)
      ;; WIP ... can't get it to detect mode yet...
      ;(let [comp-fn (if (= (vim.fn.mode) :n) :compile-buffer :compile-selection)
      ;      (ok code) ((. (require :hotpot.api.compile) comp-fn) 0)]
      (let [(ok code) ((. (require :hotpot.api.compile) :compile-range) 0 start
                                                                        stop)]
        (_G.FnlDo ok code))))

;; https://github.com/neovim/neovim/pull/13896
(fn _G.FnlDo [ok code noformat]
  (set vim.wo.scrollbind true)
  (var buf vim.g.luascratch)
  (when (not buf)
    (set buf (vim.api.nvim_create_buf false true))
    (set vim.g.luascratch buf)
    (vim.api.nvim_buf_set_option buf :filetype :lua))
  (let [nextLine (vim.gsplit code "\n" true)
        lines (icollect [v nextLine]
                v)]
    (vim.api.nvim_buf_set_lines buf 0 -1 false lines)
    (let [wnum (vim.fn.bufwinnr buf)
          jump-or-split (if (= -1 wnum) (.. :vs|b buf) (.. wnum "wincmd w"))]
      (cmd jump-or-split)
      (if (and ok (not noformat)) (cmd "%!lua-format"))
      (cmd "setl nofoldenable")
      (vim.fn.setpos "." [0 0 0 0]))))

(fn _G.Format [wait-ms]
  (vim.lsp.buf.formatting_sync nil (or wait-ms wait-default)))

;; Synchronously organise imports, courtesy of
;; https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-656372575 and
;; https://github.com/lucax88x/configs/blob/master/dotfiles/.config/nvim/lua/lt/lsp/functions.lua
(fn _G.OrgImports [wait-ms]
  (let [params (vim.lsp.util.make_range_params)]
    (set params.context {:only [:source.organizeImports]})
    (let [result (vim.lsp.buf_request_sync 0 :textDocument/codeAction params
                                           (or wait-ms wait-default))]
      (each [_ res (pairs (or result {}))]
        (each [_ r (pairs (or res.result {}))]
          (if r.edit (vim.lsp.util.apply_workspace_edit r.edit)
              (vim.lsp.buf.execute_command r.command)))))))

(fn _G.OrgJSImports []
  (vim.lsp.buf.execute_command {:arguments [(vim.fn.expand "%:p")]
                                :command :_typescript.organizeImports}))

;; inspired by https://vim.fandom.com/wiki/Smart_mapping_for_tab_completion
(fn _G.SmartTabComplete []
  (let [line (vim.fn.getline ".")
        col (vim.fn.col ".")
        ch (string.sub line (- col 1) col)
        t #(vim.api.nvim_replace_termcodes $ true true true)
        default (if (= vim.bo.omnifunc "") :<C-x><C-n> :<C-x><C-o>)]
    (t (match ch
         " " :<Tab>
         "\t" :<Tab>
         "/" :<C-x><C-f>
         _ default))))

(local cfg-files
       (let [c (vim.fn.stdpath :config)]
         (map #(string.sub $ (+ (length c) 2))
              (vim.fn.glob (.. c "/" :fnl/**/*.fnl) 0 1))))

(fn _G.CfgComplete [arg-lead]
  (vim.tbl_filter #(or (= arg-lead "") ($:find arg-lead)) cfg-files))

(fn _G.GitStatus []
  (let [branch (vim.trim (vim.fn.system "git rev-parse --abbrev-ref HEAD 2> /dev/null"))]
    (if (not= branch "")
        (let [dirty (.. (vim.fn.system "git diff --quiet || echo -n \\*")
                        (vim.fn.system "git diff --cached --quiet || echo -n \\+"))]
          (set vim.w.git_status (.. branch dirty))))))

(fn _G.ProjRelativePath []
  (string.sub (vim.fn.expand "%:p") (+ (length vim.w.proj_root) 1)))

(fn _G.LspCapabilities []
  (print (vim.inspect (collect [_ c (pairs (vim.lsp.buf_get_clients))]
                        (values c.name
                                (collect [k v (pairs c.resolved_capabilities)]
                                  (if v (values k v))))))))

(fn _G.RunTests []
  (cmd :echo)
  (var curr-fn ((. (require :nvim-treesitter) :statusline)))
  (if (not (vim.startswith curr-fn "func ")) (set curr-fn "*")
      (set curr-fn (curr-fn:sub 6 (- (curr-fn:find "%(") 1))))
  (vim.lsp.buf.execute_command {:arguments [{:URI (vim.uri_from_bufnr 0)
                                             :Tests [curr-fn]}]
                                :command :gopls.run_tests}))

;; TODO: https://github.com/neovim/neovim/pull/12378
;;       https://github.com/neovim/neovim/pull/14661
(fn _G.au [...]
  (each [name aux (pairs ...)]
    (cmd (: "aug %s | au!" :format name))
    ((all :au) aux)
    (cmd "aug END")))

(fn util.set [...]
  (each [k v (pairs ...)]
    (if (and (= (type v) :string) (vim.startswith v "+"))
        (do
          (set-forcibly! v (v:sub 2))
          (: (. vim.opt k) :append v))
        (and (= (type v) :table) (= (. v 1) :defaults))
        (: (. vim.opt k) :append (vim.list_slice v 2))
        (tset vim.opt k v))))

(fn util.kmap [mappings]
  (each [mode mx (pairs mappings)]
    (each [_ m (ipairs mx)]
      (var (lhs rhs opts) (unpack m))
      (set opts (or opts {}))
      (set opts.noremap true)
      (vim.api.nvim_set_keymap mode lhs rhs opts))))

(fn util.let [cfg]
  (each [group vars (pairs cfg)]
    (each [k v (pairs vars)]
      (if (= (type v) :table)
          (each [kk vv (pairs v)]
            (tset (. vim group) (.. k "_" kk) vv))
          (tset (. vim group) k v)))))

util

