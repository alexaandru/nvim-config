(local ns (vim.api.nvim_create_namespace :lint))
(local num #(- (tonumber $) 1))
(local [E W] [vim.diagnostic.severity.ERROR vim.diagnostic.severity.WARN])

(fn parse-actionlint [lines _]
  (let [dx []]
    (each [_ line (ipairs lines)]
      (let [(_ lnum col message) (line:match "^(.+):(%d+):(%d+): (.+)$")]
        (if (and lnum col message)
            (let [lnum (num lnum) col (num col) severity W source :actionlint]
              (table.insert dx {: lnum : col : message : severity : source})))))
    dx))

(fn actionlint [bufnr]
  (let [lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        output (vim.fn.systemlist "actionlint --oneline -" lines)
        dx (parse-actionlint output bufnr)]
    (vim.diagnostic.set ns bufnr dx)))

(fn parse-jq [lines _]
  (let [dx []]
    (each [_ line (ipairs lines)]
      (let [(message lnum col) (line:match "^jq: parse error: (.+) at line (%d+), column (%d+)$")]
        (if (and lnum col message)
            (let [lnum (num lnum) col (num col) severity E source :jq]
              (table.insert dx {: lnum : col : message : severity : source})))))
    dx))

(fn jq [bufnr]
  (let [lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        output (vim.fn.systemlist "jq empty" lines)
        dx (parse-jq output bufnr)]
    (vim.diagnostic.set ns bufnr dx)))

(fn parse-eslint [lines _]
  (let [dx []]
    (each [_ line (ipairs lines)]
      (let [(_ lnum col level message) (line:match "^(.+)%((%d+),(%d+)%): (%w+) (.+)$")]
        (if (and lnum col level message)
            (let [severity (if (= level :error) E W)
                  lnum (num lnum) col (num col) source :eslint_d]
              (table.insert dx {: lnum : col : message : severity : source})))))
    dx))

(fn eslint_d [bufnr]
  (let [file (vim.api.nvim_buf_get_name bufnr)
        lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        cmd (.. "eslint_d -f visualstudio --stdin --stdin-filename=" file)
        output (vim.fn.systemlist cmd lines)
        dx (parse-eslint output bufnr)]
    (vim.diagnostic.set ns bufnr dx)))

(let [events [:BufEnter :BufWritePost :InsertLeave :TextChanged]
      au #(vim.api.nvim_create_autocmd events {:callback $ :pattern $2})]
  (au #(let [filepath (vim.api.nvim_buf_get_name $.buf)]
         (if (filepath:match "%.github/") (actionlint $.buf))
         false) [:*.yml :*.yaml])
  (au #(jq $.buf) :*.json)
  (au #(eslint_d $.buf) [:*.js :*.ts :*.vue]))
