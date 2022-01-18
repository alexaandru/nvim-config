(fn filter [qf args]
  (let [curr-file (vim.fn.expand "%")
        filter #(vim.tbl_filter $ qf)]
    (match args
      "%" (filter #(= curr-file $.filename))
      v (filter #(string.match (or $.filename "") v))
      _ qf)))

(fn GolangCI [args]
  (var output {})

  (fn on_stdout [job data]
    (table.insert output data))

  (fn on_exit [job code]
    (let [lines (vim.tbl_flatten output)
          qf (icollect [_ v (ipairs lines)]
               (let [matches (v:gmatch "::(%S)%S+%s+file=(.*),line=(.*),col=(.*)::(.*)")
                     (type filename lnum col text) (matches)
                     lnum (tonumber lnum)
                     col (tonumber col)]
                 {: type : filename : lnum : col : text}))
          qf (filter qf args.args)]
      (when (> (length qf) 1)
        (vim.fn.setqflist qf :r)
        (vim.cmd :copen))))

  (let [job "golangci-lint run --out-format github-actions"
        opts {: on_exit : on_stdout :on_stderr on_stdout}]
    (vim.fn.jobstart job opts)))

(fn RunTests []
  (vim.cmd :echo)
  (var curr-fn ((. (require :nvim-treesitter) :statusline)))
  (if (not (vim.startswith curr-fn "func ")) (set curr-fn "*")
      (set curr-fn (curr-fn:sub 6 (- (curr-fn:find "%(") 1))))
  (vim.lsp.buf.execute_command {:arguments [{:URI (vim.uri_from_bufnr 0)
                                             :Tests [curr-fn]}]
                                :command :gopls.run_tests}))

{: GolangCI : RunTests}

