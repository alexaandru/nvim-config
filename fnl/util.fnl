(local wait-default 2000)

;; https://github.com/neovim/neovim/pull/13896
(fn fnl-do [ok code noformat]
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
    (let [cmd vim.cmd
          wnum (vim.fn.bufwinnr buf)
          jump-or-split (if (= -1 wnum) (.. :vs|b buf) (.. wnum "wincmd w"))]
      (cmd jump-or-split)
      (if (and ok (not noformat)) (cmd "%!lua-format"))
      (cmd "setl nofoldenable")
      (vim.fn.setpos "." [0 0 0 0]))))

(fn _G.FnlEval [start stop]
  (if (= vim.bo.filetype :fennel)
      (let [{: eval-range} (require :hotpot.api.eval)
            (any) (eval-range 0 start stop)]
        (fnl-do true (vim.inspect any) true))))

(fn _G.FnlCompile [start stop]
  (if (= vim.bo.filetype :fennel)
      (let [{: compile-range} (require :hotpot.api.compile)
            (ok code) (compile-range 0 start stop)]
        (fnl-do ok code))))

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
        ch (line:sub (- col 1) col)
        ch (if (line:match "/") "/" ch)
        t #(vim.api.nvim_replace_termcodes $ true true true)
        default (if (= vim.bo.omnifunc "") :<C-x><C-n> :<C-x><C-o>)]
    (t (match ch
         "" :<Tab>
         " " :<Tab>
         "\t" :<Tab>
         "/" :<C-x><C-f>
         _ default))))

;; https://www.youtube.com/watch?v=NUr-VvaOEHQ
(fn _G.Compe []
  ;(print (vim.inspect (vim.lsp.buf.completion)))
  (let [words [:hello :world]]
    (vim.fn.complete (vim.fn.col ".") words))
  "")

(local cfg-files
       (let [c (vim.fn.stdpath :config)]
         (vim.tbl_map #($:sub (+ (length c) 2 (length :fnl/)))
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
  (vim.cmd :echo)
  (var curr-fn ((. (require :nvim-treesitter) :statusline)))
  (if (not (vim.startswith curr-fn "func ")) (set curr-fn "*")
      (set curr-fn (curr-fn:sub 6 (- (curr-fn:find "%(") 1))))
  (vim.lsp.buf.execute_command {:arguments [{:URI (vim.uri_from_bufnr 0)
                                             :Tests [curr-fn]}]
                                :command :gopls.run_tests}))

(fn _G.GolangCI []
  (let [out (vim.fn.system "golangci-lint run --out-format github-actions")
        lines (vim.fn.split out "\n")
        qf (icollect [_ v (ipairs lines)]
             (let [matches (v:gmatch "::(%S)%S+%s+file=(.*),line=(.*),col=(.*)::(.*)")
                   (type filename lnum col text) (matches)
                   lnum (tonumber lnum)
                   col (tonumber col)]
               {: type : filename : lnum : col : text}))]
    (when (> (length qf) 1)
      (vim.fn.setqflist qf :r)
      (vim.cmd :copen))))

nil

