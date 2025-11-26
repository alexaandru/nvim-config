(local (has-icons icons) (pcall require :mini.icons))
(local get-icon (or (and has-icons icons.get) nil))

(fn mark-package-sources []
  (let [bufnr (vim.api.nvim_get_current_buf)
        filename (vim.fn.expand "%:t")]
    (if (= filename :packages.fnl)
        (let [ns (vim.api.nvim_create_namespace :pack_sources)
              clr-ns vim.api.nvim_buf_clear_namespace]
          (clr-ns bufnr ns 0 (- 1))
          (let [parser (vim.treesitter.get_parser bufnr :fennel)
                tree (. (parser:parse) 1)
                root (tree:root)
                query (vim.treesitter.query.get :fennel :highlights)
                marked {}]
            (each [id node (query:iter_captures root bufnr 0 (- 1))]
              (if (= (. query.captures id) :string.special.pack_name)
                  (let [(row col) (node:start)
                        key (.. row ":" col)]
                    (if (not (. marked key))
                        (let [xt-mrk vim.api.nvim_buf_set_extmark
                              xt-mrk #(xt-mrk bufnr ns row col
                                              {:virt_text [[(.. $ " ") $2]]
                                               :virt_text_pos :inline})]
                          (if get-icon
                              (let [(icon hl) (get-icon :directory :nvim)
                                    icon (or icon "📦")
                                    hl (or hl :Special)]
                                (xt-mrk icon hl))
                              (let [icon "📦"
                                    hl :Special]
                                (xt-mrk icon hl)))
                          (tset marked key true)))))))))))

(let [au vim.api.nvim_create_autocmd]
  (au [:BufEnter :BufReadPost :BufWritePost :InsertLeave]
      {:callback mark-package-sources :pattern :packages.fnl}))

(let [com vim.api.nvim_create_user_command]
  (com :MarkPackages mark-package-sources {}))
