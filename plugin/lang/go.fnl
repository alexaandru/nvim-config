(local namespace (vim.api.nvim_create_namespace :golangci-lint-manual))

(fn GolangCI [_args]
  (local output {})

  (fn on_stdout [_ data]
    (each [_ line (ipairs data)]
      (if (not= line "") (table.insert output line))))

  (fn on_exit []
    (let [json-str (table.concat output "")
          ;; Find where JSON starts and ends - just extract the JSON object
          json-start (json-str:find "{\"Issues\":")
          json-str (if json-start (json-str:sub json-start) json-str)
          ;; Also strip any trailing log messages
          json-str (json-str:gsub "level=.-\n" "")
          (ok result) (pcall vim.json.decode json-str)
          diagnostics (if ok
                          (icollect [_ issue (ipairs (or result.Issues []))]
                            (let [pos issue.Pos
                                  severity (match issue.Severity
                                             :error vim.diagnostic.severity.ERROR
                                             _ vim.diagnostic.severity.WARN)]
                              {:bufnr (vim.fn.bufnr pos.Filename)
                               :lnum (- pos.Line 1)
                               :col (- pos.Column 1)
                               :severity severity
                               :source :golangci-lint
                               :message (.. issue.FromLinter ": " issue.Text)}))
                          [])
          ;; Group diagnostics by buffer
          by-bufnr {}]
      (each [_ diag (ipairs diagnostics)]
        (when (>= diag.bufnr 0)
          (if (not (. by-bufnr diag.bufnr)) (tset by-bufnr diag.bufnr []))
          (table.insert (. by-bufnr diag.bufnr) diag)))
      ;; Set diagnostics for each buffer
      (each [bufnr diags (pairs by-bufnr)]
        (vim.diagnostic.set namespace bufnr diags))
      (if (= (length diagnostics) 0)
          (print :OK)
          (print (.. (length diagnostics) " issue(s) found")))))

  (let [bufdir (vim.fn.expand "%:p:h")
        root (vim.fn.system "git rev-parse --show-toplevel")
        root (vim.fn.trim root)
        modfile (.. root "/tools/go.mod")
        cmd (.. "go tool -modfile=" modfile
                " golangci-lint run --output.json.path=stdout --show-stats=false --issues-exit-code=1")
        job (.. "cd " (vim.fn.shellescape bufdir) " && " cmd)
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
