(fn format-buffer []
  (let [view (vim.fn.winsaveview)
        fdm vim.wo.foldmethod]
    (set vim.wo.foldmethod :manual)
    (vim.cmd "silent! norm ggVGgq")
    (vim.fn.winrestview view)
    (vim.schedule #(do (set vim.wo.foldmethod fdm)
                       (vim.cmd "norm zR")))
    false))

(fn format-json []
  (let [lines (vim.api.nvim_buf_get_lines 0 0 -1 false)
        output (vim.fn.systemlist "jq ." lines)]
    (if (= vim.v.shell_error 0)
        (vim.api.nvim_buf_set_lines 0 0 -1 false output)
        (vim.notify (.. "Failed to format JSON: " (. output 1))
                    vim.log.levels.ERROR))
    false))

;; fnlfmt: skip
(local compat-format [:*.fnl :*.d2 :*.md :*.js :*.ts :*.vue
                      :*.yaml :*.yml :*.html :*.scss :*.css])

(let [format (vim.api.nvim_create_augroup :Format {:clear true})
      au #(vim.api.nvim_create_autocmd $1 (doto $2 (tset :group format)))]
  (au :FileType {:command "setl fp=fnlfmt\\ -" :pattern :fennel})
  (au :FileType {:command "setl fp=d2\\ fmt\\ -" :pattern :d2})
  (au :FileType {:callback #(set vim.bo.formatprg
                       "prettier --no-semi --stdin-filepath=% | eslint_d --fix-to-stdout --stdin --stdin-filename=%")
                 :pattern [:javascript :typescript :vue]})
  (au :FileType {:command "setl fp=prettier\\ --stdin-filepath=%"
                 :pattern [:yaml :html :scss :css :markdown]})
  (au :BufWritePre {:callback #(if vim.bo.modified (format-buffer)) :pattern compat-format})
  (au :BufWritePre {:callback #(if vim.bo.modified (format-json)) :pattern :*.json}))
