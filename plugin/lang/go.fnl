(fn filter [qf args]
  (let [curr-file (vim.fn.expand "%")
        filter #(vim.tbl_filter $ qf)]
    (case args
      "%" (filter #(= curr-file $.filename))
      v (filter #(string.match (or $.filename "") v))
      _ qf)))

(fn GolangCI [args]
  (local output {})

  (fn on_stdout [_ data] ;; job
    (table.insert output data))

  (fn on_exit []
    ;; job code
    (let [lines (: (: (vim.iter output) :flatten) :totable)
          json-str (table.concat lines "")
          (ok result) (pcall vim.json.decode json-str)
          qf (if ok
                 (icollect [_ issue (ipairs (or result.Issues []))]
                   (let [pos issue.Pos
                         severity (if (= issue.Severity :error) :E :W)]
                     {:filename pos.Filename
                      :lnum pos.Line
                      :col pos.Column
                      :type severity
                      :text (.. issue.FromLinter ": " issue.Text)}))
                 [])
          qf (filter qf args.args)
          tbl-is-not-empty #(not (vim.tbl_isempty $))
          qf (vim.tbl_filter tbl-is-not-empty qf)]
      (when (> (length qf) 0)
        (vim.fn.setqflist qf :r)
        (vim.cmd.copen))
      (if (= (length qf) 0)
          (print :OK))))

  (let [job "go tool -modfile=tools/go.mod golangci-lint run --output.json.path=stdout --show-stats=false --issues-exit-code=1"
        opts {: on_exit : on_stdout :on_stderr on_stdout}]
    (vim.fn.jobstart job opts)))

(fn RunTests []
  (vim.cmd.echo)
  (var curr-fn ((. (require :nvim-treesitter) :statusline)))
  (if (not (vim.startswith curr-fn "func ")) (set curr-fn "*")
      (set curr-fn (curr-fn:sub 6 (- (curr-fn:find "%(") 1))))
  (let [bufnr (vim.api.nvim_get_current_buf)
        clients (vim.lsp.get_clients {: bufnr})]
    (each [_ client (ipairs clients)]
      (if (= client.name :gopls)
          (client:exec_cmd {:arguments [{:URI (vim.uri_from_bufnr 0)
                                         :Tests [curr-fn]}]
                            :command :gopls.run_tests})))))

(let [opts {:range "%" :nargs "*" :bar true}
      com vim.api.nvim_create_user_command]
  (each [name func (pairs {: GolangCI : RunTests})]
    (com name func opts)))

(each [lhs rhs (pairs {:<F5> "<Cmd>GolangCI %<CR>" :<F6> :<Cmd>RunTests<CR>})]
  (vim.keymap.set :n lhs rhs {:silent true}))
