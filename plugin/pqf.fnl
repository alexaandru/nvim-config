;; Inspired by https://gitlab.com/yorickpeterse/nvim-pqf
(local type-to-sign {:E "DiagnosticSignError"
                     :W "DiagnosticSignWarn"
                     :I "DiagnosticSignInfo"
                     :N "DiagnosticSignHint"})

(fn filter-qf-text [info]
  (let [items (if (= info.quickfix 1)
                  (. (vim.fn.getqflist {:id info.id :items 1}) :items)
                  (. (vim.fn.getloclist info.winid {:id info.id :items 1})
                     :items))
        lines []]
    (for [i info.start_idx info.end_idx]
      (let [item (. items i)]
        (if (and (> item.bufnr 0) (> item.lnum 0))
            (table.insert lines
                          (string.format "%s|%d col %d| %s"
                                         (vim.fn.bufname item.bufnr) item.lnum
                                         item.col item.text)))))
    lines))

(fn add-qf-signs []
  (let [qflist (vim.fn.getqflist {:items 1 :qfbufnr 1})
        items qflist.items
        buf qflist.qfbufnr]
    (vim.fn.sign_unplace "pqf" {:buffer buf})
    (each [idx item (ipairs items)] ; Skip context lines (no filename or line number)
      (if (and (> item.bufnr 0) (> item.lnum 0))
          (let [sign-name (. type-to-sign item.type)]
            (if sign-name
                (vim.fn.sign_place 0 "pqf" sign-name buf
                                   {:lnum idx :priority 10})))))))

(set vim.g.pqf_add_signs add-qf-signs)
(set vim.g.pqf_filter_text filter-qf-text)

;; fnlfmt: skip
(vim.api.nvim_set_option_value :quickfixtextfunc "v:lua.vim.g.pqf_filter_text" {})

;; fnlfmt: skip
(vim.api.nvim_create_autocmd "BufWinEnter" {
     :pattern "*"
     :callback #(if (= vim.bo.filetype "qf")
                    (vim.schedule #(if (> (length (vim.fn.getqflist)) 0) (vim.g.pqf_add_signs))))
     :desc "Add PQF signs to quickfix list"})
