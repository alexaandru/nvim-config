{:capabilities {:offsetEncoding [:utf-8 :utf-16]}
 :cmd [:fennel-ls]
 :filetypes [:fennel]
 :root_dir (fn [bufnr on-dir]
             (local fname (vim.api.nvim_buf_get_name bufnr))

             (fn has-fls-project-cfg [path]
               (local fnlpath (vim.fs.joinpath path :flsproject.fnl))
               (= (. (or (vim.uv.fs_stat fnlpath) {}) :type) :file))

             (on-dir (or (: (vim.iter (vim.fs.parents fname)) :find
                            has-fls-project-cfg)
                         (vim.fs.root 0 :.git))))
 :settings {}}
