(local ns (vim.api.nvim_create_namespace :lint))

(fn parse-actionlint [lines _]
  (let [diagnostics []]
    (each [_ line (ipairs lines)]
      (let [(_ lnum col msg) (line:match "^(.+):(%d+):(%d+): (.+)$")]
        (if (and lnum col msg)
            (table.insert diagnostics
                          {:lnum (- (tonumber lnum) 1)
                           :col (- (tonumber col) 1)
                           :message msg
                           :severity vim.diagnostic.severity.WARN
                           :source :actionlint}))))
    diagnostics))

(fn actionlint [bufnr]
  (let [lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        output (vim.fn.systemlist "actionlint --oneline -" lines)
        diagnostics (parse-actionlint output bufnr)]
    (vim.diagnostic.set ns bufnr diagnostics)))

(fn parse-jq [lines _]
  (let [diagnostics []]
    (each [_ line (ipairs lines)]
      (let [(msg lnum col) (line:match "^jq: parse error: (.+) at line (%d+), column (%d+)$")]
        (if (and lnum col msg)
            (table.insert diagnostics
                          {:lnum (- (tonumber lnum) 1)
                           :col (- (tonumber col) 1)
                           :message msg
                           :severity vim.diagnostic.severity.ERROR
                           :source :jq}))))
    diagnostics))

(fn jq [bufnr]
  (let [lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        output (vim.fn.systemlist "jq empty" lines)
        diagnostics (parse-jq output bufnr)]
    (vim.diagnostic.set ns bufnr diagnostics)))

(fn parse-eslint [lines _]
  (let [diagnostics []]
    (each [_ line (ipairs lines)]
      (let [(_ lnum col level msg) (line:match "^(.+)%((%d+),(%d+)%): (%w+) (.+)$")]
        (if (and lnum col level msg)
            (let [severity (if (= level :error)
                               vim.diagnostic.severity.ERROR
                               vim.diagnostic.severity.WARN)]
              (table.insert diagnostics
                            {:lnum (- (tonumber lnum) 1)
                             :col (- (tonumber col) 1)
                             :message msg
                             : severity
                             :source :eslint_d})))))
    diagnostics))

(fn eslint_d [bufnr]
  (let [file (vim.api.nvim_buf_get_name bufnr)
        lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        cmd (.. "eslint_d -f visualstudio --stdin --stdin-filename=" file)
        output (vim.fn.systemlist cmd lines)
        diagnostics (parse-eslint output bufnr)]
    (vim.diagnostic.set ns bufnr diagnostics)))

(let [events [:BufEnter :BufWritePost :InsertLeave :TextChanged]
      au #(vim.api.nvim_create_autocmd events {:callback $ :pattern $2})]
  (au #(let [filepath (vim.api.nvim_buf_get_name $.buf)]
         (if (filepath:match "%.github/") (actionlint $.buf))
         false) [:*.yml :*.yaml])
  (au #(jq $.buf) :*.json)
  (au #(eslint_d $.buf) [:*.js :*.ts :*.vue]))
