(local format-prgs
       (let [prettier "prettier --no-semi --stdin-filepath=%"
             eslint "eslint_d --fix-to-stdout --stdin --stdin-filename=%"]
         {:fennel "fnlfmt -"
          :d2 "d2 fmt -"
          :json "jq ."
          [:javascript :typescript :vue] (.. prettier :| eslint)
          [:yaml :html :scss :css :markdown] prettier}))

;; fnlfmt: skip
(local ext [:*.fnl :*.d2 :*.md :*.js :*.ts :*.vue
            :*.yaml :*.yml :*.html :*.scss :*.css :*.json])

(fn format []
  (let [lines (vim.api.nvim_buf_get_lines 0 0 -1 false)
        fname (vim.api.nvim_buf_get_name 0)
        cmd (vim.bo.formatprg:gsub "%%" fname)
        output (vim.fn.systemlist cmd lines)]
    (if (= vim.v.shell_error 0)
        (let [view (vim.fn.winsaveview)]
          (vim.api.nvim_buf_set_lines 0 0 -1 false output)
          (vim.fn.winrestview view)))
    false))

(let [group (vim.api.nvim_create_augroup :Format {:clear true})
      opts #(if (= (type $) :string)
                {:command $ : group :pattern (or $2 :*)}
                {:callback $ : group :pattern (or $2 :*)})
      au #(vim.api.nvim_create_autocmd $ (opts $2 $3))]
  (each [pat fp (pairs format-prgs)]
    (au :FileType #(set vim.bo.formatprg fp) pat))
  (au :BufWritePre #(if vim.bo.modified (format)) ext))
