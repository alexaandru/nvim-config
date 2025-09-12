;; Courtesy of https://pastebin.com/x0pSjk9c
(local error-query (vim.treesitter.query.parse :query "[(ERROR)(MISSING)] @a"))

(local namespace (vim.api.nvim_create_namespace :treesitter.diagnostics))

;; fnlfmt: skip
(fn mk-parse-trees [parser args diagnostics]
  (fn [_ trees]
    (when trees
      (parser:for_each_tree (fn [tree ltree]
                              (when (and (not= (ltree:lang) :comment) (not= (ltree:lang) :markdown))
                                (each [_ node (error-query:iter_captures (tree:root) args.buf)]
                                  (var (lnum col end-lnum end-col) (node:range))
                                  (local parent (node:parent))
                                  (local should-skip (and parent (= (parent:type) "ERROR") (= (parent:range) (node:range))))
                                  (when (not should-skip)
                                    (when (> end-lnum lnum)
                                      (set end-lnum (+ lnum 1))
                                      (set end-col 0))
                                    (local diagnostic {:bufnr args.buf :code (string.format "%s-syntax" (ltree:lang))
                                            : col :end_col end-col :end_lnum end-lnum : lnum :source :treesitter
                                            :message "" : namespace :severity vim.diagnostic.severity.ERROR})
                                    (if (node:missing)
                                        (set diagnostic.message
                                             (string.format "missing `%s`" (node:type)))
                                        (set diagnostic.message :error))
                                    (local previous (node:prev_sibling))
                                    (when (and previous (not= (previous:type) :ERROR))
                                      (local previous-type
                                             (or (and (previous:named) (previous:type))
                                                 (string.format "`%s`" (previous:type))))
                                      (set diagnostic.message
                                           (.. diagnostic.message " after " previous-type)))
                                    (when (and parent (not= (parent:type) "ERROR") (or (= previous nil) (not= (previous:type) (parent:type))))
                                      (set diagnostic.message
                                           (.. diagnostic.message " in " (parent:type))))
                                    (table.insert diagnostics diagnostic)))))))))

; Blacklist filetypes that have a LSP configured.
; We only want Tree-sitter diagnostics if there is no LSP.
(local blacklist (icollect [_ v (pairs vim.lsp.config._configs)]
                   (if v.filetypes (unpack v.filetypes))))

(fn diagnose [args]
  (when (and (vim.diagnostic.is_enabled {:bufnr args.buf})
             (= (. vim.bo args.buf :buftype) "")
             (not (vim.tbl_contains blacklist (. vim.bo args.buf :filetype))))
    (let [diagnostics {}
          parser (vim.treesitter.get_parser args.buf nil {:error false})]
      (when parser
        (parser:parse false (mk-parse-trees parser args diagnostics)))
      (vim.diagnostic.set namespace args.buf diagnostics))))

(local autocmd-group
       (vim.api.nvim_create_augroup :editor.treesitter {:clear true}))

(vim.api.nvim_create_autocmd [:FileType :TextChanged :InsertLeave]
                             {:callback (vim.schedule_wrap diagnose)
                              :desc "treesitter diagnostics"
                              :group autocmd-group})
