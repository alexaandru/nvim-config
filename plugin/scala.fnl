;; fnlfmt: skip
(vim.treesitter.query.add_directive :magic_set_lang!
     (fn [maTch _pattern bufnr pred metadata]
       (let [cap-id (. pred 2)
             node (. maTch cap-id)]
         (when node
           (local start-row (node:range))
           (local lines (vim.api.nvim_buf_get_lines bufnr 0 (+ start-row 1) false))
           (var lang nil)
           (var found false)

           (fn norm-lang [s]
             (when s
               (let [s (s:lower)]
                 (if (or (= s :md) (= s :markdown)) :markdown
                     (= s :js) :javascript
                     (= s :ts) :typescript
                     s))))

           (for [i start-row 0 -1 &until found]
             (let [l (or (. lines (+ i 1)) "")
                   m (l:match "^%s*//%s*MAGIC%s+%%%s*([%w_%-]+)")]
               (if m
                   (do
                     (set lang (norm-lang m))
                     (set found true))
                   (set found (not (l:match "^%s*//%s*MAGIC%s+"))))))

           ;; fallback language
           (set lang (or lang :python))

           (tset metadata :injection.language lang)
           (tset metadata :injection.combined true)
           (tset metadata :injection.include-children false)

           true))))
