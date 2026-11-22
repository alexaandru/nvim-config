;; Prune tree-sitter parsers that are not in the nvim-treesitter registry.
;; Leftovers from the master branch era make a bare :TSUpdate log
;; 'Parser not available for language "..."' errors, because it iterates
;; every installed parser on disk (config.get_installed).

;; Parsers managed outside the nvim-treesitter registry (never prune).
(local keep [:d2])

(fn delete-file [path]
  (when (= 1 (vim.fn.filereadable path))
    (vim.fn.delete path)))

(fn delete-dir [dir]
  (when (= 1 (vim.fn.isdirectory dir))
    (each [name _ (vim.fs.dir dir)]
      (delete-file (vim.fs.joinpath dir name)))
    (vim.fn.delete dir :d)))

(fn prune []
  (let [ts-config (require :nvim-treesitter.config)
        registry (require :nvim-treesitter.parsers)
        orphan? (fn [lang]
                  (and (= nil (. registry lang))
                       (not (vim.list_contains keep lang))))
        parser-dir (ts-config.get_install_dir :parser)
        queries-dir (ts-config.get_install_dir :queries)
        info-dir (ts-config.get_install_dir :parser-info)
        pruned []]
    ;; Orphaned parsers: parser .so, queries dir
    (each [_ lang (ipairs (ts-config.get_installed))]
      (when (orphan? lang)
        (delete-file (vim.fs.joinpath parser-dir (.. lang :.so)))
        (delete-dir (vim.fs.joinpath queries-dir lang))
        (table.insert pruned lang)))
    ;; Stale revision files (incl. parsers already removed by hand)
    (each [name _ (vim.fs.dir info-dir)]
      (let [lang (name:match "^(.+)%.revision$")]
        (when (and lang (orphan? lang))
          (delete-file (vim.fs.joinpath info-dir name))
          (when (not (vim.list_contains pruned lang))
            (table.insert pruned lang)))))
    (each [_ lang (ipairs pruned)]
      (print (.. "Pruned orphaned treesitter parser: " lang)))))

(vim.api.nvim_create_user_command :TSPrune prune
                                  {:desc "Prune orphaned treesitter parsers"})

(vim.schedule #(let [(ok err) (pcall prune)]
                 (when (not ok)
                   (vim.notify (.. "TSPrune failed: " (tostring err))
                               vim.log.levels.ERROR))))
