(local ns (vim.api.nvim_create_namespace :package_info))

(fn vtext [opts line col]
  (set-forcibly! col (or col 0))
  (if (= (type opts) :string)
      (set-forcibly! opts {:virt_text [[opts :DiagnosticError]]}))
  (if (not opts.virt_text_pos) (set opts.virt_text_pos :eol))
  (vim.api.nvim_buf_set_extmark 0 ns line col opts))

(fn get-info []
  (vim.json.decode (vim.fn.system "npm out --json")))

(fn virt-text [info]
  (let [text {:virt_text [[(.. " 🚩 " info.current ",") :DiagnosticInfo]]}
        vt #(table.insert text.virt_text [(.. " " $2 (or $3 "")) $1])]
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
    (vim.schedule #(display-info-item k v))))

(fn update-info []
  (let [info (get-info)]
    (display-info info)))

(fn PackageInfo []
  (when (not vim.b.package_info)
    (vim.schedule update-info)
    (set vim.b.package_info true)))

(let [group (vim.api.nvim_create_augroup :PackageInfo {:clear true})
      opts {:callback PackageInfo :pattern :package.json : group}]
  (vim.api.nvim_create_autocmd :BufEnter opts))

