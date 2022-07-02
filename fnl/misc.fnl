(fn LspCapabilities []
  (vim.notify (vim.inspect (collect [_ c (pairs (vim.lsp.buf_get_clients))]
                             c.name
                             (collect [k v (pairs c.server_capabilities)]
                               (if v (values k v)))))))

(fn is-quittable []
  (let [{:buftype bt :filetype ft} (vim.fn.getbufvar "%" "&")]
    (or (vim.tbl_contains [:quickfix :terminal :nofile] bt) (= ft :netrw))))

(fn last-window []
  (= -1 (vim.fn.winbufnr 2)))

(fn LastWindow []
  (if (and (is-quittable) (last-window))
      (vim.cmd "norm ZQ")))

;; https://github.com/neovim/neovim/pull/13896
(fn get-range []
  ;; https://github.com/neovim/neovim/pull/13896#issuecomment-774680224
  (var [_ l1] (vim.fn.getpos :v))
  (var [_ l2] (vim.fn.getcurpos))
  (when (= l1 l2)
    (set l1 1)
    (set l2 (vim.fn.line "$")))
  (when (> l1 l2)
    (local tmp l1)
    (set l1 l2)
    (set l2 tmp))
  [l1 l2])

(fn get-selection []
  (let [[l1 l2] (get-range)
        lines (vim.fn.getline l1 l2)
        text (table.concat lines "\n")]
    text))

(fn Gdiff []
  (vim.cmd :SetProjRoot)
  (let [path (vim.fn.expand "%:p")
        proj-rel-path (path:sub (+ (length vim.w.proj_root) 1))
        cmd "exe 'sil !lcd %s && git show HEAD^:%s > /tmp/gdiff' | diffs /tmp/gdiff"
        cmd (cmd:format vim.w.proj_root proj-rel-path)]
    (vim.cmd cmd)))

{: LspCapabilities : LastWindow : Gdiff : get-range : get-selection}

