{:capabilities {:workspace {:didChangeWorkspaceFolders {:dynamicRegistration true}}}
 :cmd [:gh-actions-language-server :--stdio]
 :filetypes [:yaml]
 :handlers {:actions/readFile (fn [_ result]
                                (if (not= (type result.path) :string)
                                    (values nil nil)
                                    (let [file-path (vim.uri_to_fname result.path)]
                                      (if (not= (vim.fn.filereadable file-path)
                                                1)
                                          (values nil nil)
                                          (let [f (assert (io.open file-path :r))
                                                text (f:read :*a)]
                                            (f:close)
                                            (values text nil))))))}
 :init_options {}
 :root_dir (fn [bufnr on-dir]
             (let [name (vim.api.nvim_buf_get_name bufnr)
                   parent (vim.fs.dirname name)
                   parent-is? #(vim.endswith parent $)]
               (if (parent-is? "/.github/workflows")
                   (on-dir parent))))}
