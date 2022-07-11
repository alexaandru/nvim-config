(local ns (vim.api.nvim_create_namespace :package_info))

(fn vtext [opts line col]
  (set-forcibly! col (or col 0))
  (if (= (type opts) :string)
      (set-forcibly! opts {:virt_text [[opts :DiagnosticError]]}))
  (if (not opts.virt_text_pos) (set opts.virt_text_pos :eol))
  (vim.api.nvim_buf_set_extmark 0 ns line col opts))

(fn virt-text [info]
  (let [text {:virt_text []}
        vt #(table.insert text.virt_text [(.. " " (or $2 :n/a) (or $3 "")) $1])]
    (vt :DiagnosticInfo info.current ",")
    (if (= info.wanted info.current) (vt :DiagnosticError info.latest)
        (not= info.wanted info.latest)
        (do
          (vt :DiagnosticWarn info.wanted ",")
          (vt :DiagnosticError info.latest))
        (vt :DiagnosticHint info.wanted))
    text))

(fn display-info-item [name info]
  (vtext (virt-text info) (- (vim.fn.search (.. "\"" name "\"")) 1)))

(fn display-info [info]
  (each [k v (pairs info)]
    (display-info-item k v)))

(fn update-info []
  (var json "")

  (fn on_stdout [_ data]
    (set json (.. json (table.concat data))))

  (fn on_exit [_ code]
    (set vim.b.package_info true)
    (display-info (vim.json.decode json)))

  (let [cmd "npm out --json"
        opts {: on_exit : on_stdout :on_stderr on_stdout}]
    (vim.fn.jobstart cmd opts)))

(let [group (vim.api.nvim_create_augroup :PackageInfo {:clear true})
      callback #(if (not vim.b.package_info) (update-info))
      pattern :package.json]
  (vim.api.nvim_create_autocmd :BufEnter {: group : callback : pattern}))

