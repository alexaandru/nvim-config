(local ns (vim.api.nvim_create_namespace :lint))
(local num #(- (tonumber $) 1))
(local [E W] (let [s vim.diagnostic.severity] [s.ERROR s.WARN]))
(local golangci-jobs {})

(fn parse-jq [lines _]
  (let [dx []]
    (each [_ line (ipairs lines)]
      (let [(message lnum col) (line:match "^jq: parse error: (.+) at line (%d+), column (%d+)$")]
        (if (and lnum col message)
            (let [lnum (num lnum)
                  col (num col)
                  severity E
                  source :jq]
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
                  lnum (num lnum)
                  col (num col)
                  source :eslint_d]
              (table.insert dx {: lnum : col : message : severity : source})))))
    dx))

(fn eslint_d [bufnr]
  (let [file (vim.api.nvim_buf_get_name bufnr)
        lines (vim.api.nvim_buf_get_lines bufnr 0 -1 false)
        cmd (.. "eslint_d -f visualstudio --stdin --stdin-filename=" file)
        output (vim.fn.systemlist cmd lines)
        dx (parse-eslint output bufnr)]
    (vim.diagnostic.set ns bufnr dx)))

(fn parse-golangci [bufnr result]
  (icollect [_ issue (ipairs (or result.Issues []))]
    (let [pos issue.Pos
          severity (case issue.Severity
                     :error E
                     _ W)
          issue-bufnr (vim.fn.bufnr pos.Filename)]
      (if (= issue-bufnr bufnr)
          (let [message (.. issue.FromLinter ": " issue.Text)
                lnum (num pos.Line)
                col (num pos.Column)
                source :golangci-lint]
            {: bufnr : lnum : col : severity : source : message})))))

(fn golangci [bufnr]
  ;; Cancel any existing job for this buffer
  (if (. golangci-jobs bufnr)
      (vim.fn.jobstop (. golangci-jobs bufnr)))
  (local output [])

  (fn on_stdout [_ data]
    (each [_ line (ipairs data)]
      (if (not= line "") (table.insert output line))))

  (fn on_exit []
    ;; Clear job tracking
    (tset golangci-jobs bufnr nil)
    ;; Clear all existing diagnostics from this namespace first
    (vim.diagnostic.reset ns bufnr)
    (let [json-str (table.concat output "")
          ;; Find where JSON starts and ends - just extract the JSON object
          json-start (json-str:find "{\"Issues\":")
          json-str (if json-start (json-str:sub json-start) json-str)
          ;; Also strip any trailing log messages
          json-str (json-str:gsub "level=.-\n" "")
          (ok result) (pcall vim.json.decode json-str)
          diagnostics (if ok (parse-golangci bufnr result) [])]
      (vim.diagnostic.set ns bufnr (vim.tbl_filter #(not= $ nil) diagnostics))
      ;; Populate quickfix with all issues from the entire run
      (if (and ok result.Issues)
          (let [qflist (icollect [_ issue (ipairs result.Issues)]
                         (let [pos issue.Pos]
                           {:filename pos.Filename
                            :lnum pos.Line
                            :col pos.Column
                            :text (.. issue.FromLinter ": " issue.Text)
                            :type (if (= issue.Severity :error) :E :W)}))
                current-qf (vim.fn.getqflist {:title 0})
                current-title (or current-qf.title "")
                new-title (.. "golangci-lint: " vim.w.proj_root)]
            ;; Only overwrite if empty or it's THIS exact module's list
            (if (or (= current-title "") (= current-title new-title))
                (vim.fn.setqflist [] " " {:items qflist :title new-title}))))))

  (let [bufdir (vim.fn.expand "%:p:h")
        modfile (.. vim.w.proj_root "/tools/go.mod")
        cmd (.. "go tool -modfile=" modfile
                " golangci-lint run --output.json.path=stdout --show-stats=false --issues-exit-code=1")
        job (.. "cd " (vim.fn.shellescape bufdir) " && " cmd)
        opts {: on_exit : on_stdout :on_stderr on_stdout}
        job-id (vim.fn.jobstart job opts)]
    ;; Track the job
    (tset golangci-jobs bufnr job-id)))

(vim.cmd.SetProjRoot)

(let [au #(vim.api.nvim_create_autocmd $1 {:callback $2 :pattern $3})]
  (au [:BufEnter :BufWritePost :InsertLeave :TextChanged] #(jq $.buf) :*.json)
  (au [:BufEnter :BufWritePost :InsertLeave :TextChanged] #(eslint_d $.buf)
      [:*.js :*.ts :*.vue])
  (au [:BufEnter :BufWritePost] #(golangci $.buf) :*.go))
