(fn open-at-position [args]
  (let [name args.file
        buf args.buf]
    (fn open! [f row col]
      (if (= 1 (vim.fn.filereadable f))
          (vim.schedule #(do
                           (vim.cmd (.. "edit " (vim.fn.fnameescape f)))
                           (vim.api.nvim_win_set_cursor 0 [row col])
                           (pcall vim.api.nvim_buf_delete buf {:force true})))))

    (case (name:match "^(.+):(%d+):(%d+)$")
      (f r c) (open! f (tonumber r) (- (tonumber c) 1))
      _ (case (name:match "^(.+):(%d+)$")
          (f r) (open! f (tonumber r) 0)))))

(fn set-winbar [_args]
  (if (= vim.bo.buftype "")
      (let [path (.. (vim.fn.expand "%:p:h:t") "/" (vim.fn.expand "%:t"))
            winbar (.. "%= " path " %{% luaeval('vim.diagnostic.status()') %}"
                       " %{% luaeval('vim.lsp.status()') %}")]
        (set vim.wo.winbar winbar))))

(let [group (vim.api.nvim_create_augroup :Setup {:clear true})
      ts-start #(let [_ (pcall vim.treesitter.start)]
                  false)
      opts #(if (= (type $) :string)
                {:command $ : group :pattern $2}
                {:callback $ : group :pattern $2})
      au #(vim.api.nvim_create_autocmd $ (opts $2 $3))]
  (au :BufNewFile open-at-position "*:*")
  (au :VimEnter :CdProjRoot)
  (au :VimResized "wincmd =")
  (au :TextYankPost #(vim.hl.hl_op {:higroup :Visual :timeout 450}))
  (au :TextPutPost #(vim.hl.hl_op {:higroup :Visual :timeout 450}))
  (au :User "sil keepp g/^\\./d _" :DirReadPost)
  (au :User "setl stc=%{%v:lua.nvim_dir_statuscolumn()%} scl=no nonu nornu"
      :DirReadPost)
  (au :TermOpen :startinsert)
  (au :TermClose #(if ($.file:find :/Downloads/) (vim.cmd.quit)))
  (au :FileType "wincmd L" :help)
  (au :FileType "setl spell spl=en_us" "gitcommit,asciidoc,markdown")
  (au :FileType "setl ts=2 sw=2 sts=2 fdls=0" "lua,vim,zsh,sh")
  (au :FileType "setl ts=4 sw=4 noet cole=1" :go)
  (au :FileType ts-start)
  (au :BufEnter :LastWindow)
  (au :BufEnter "setl ft=nginx" :nginx/*)
  (au :BufEnter "setl ft=risor" :*.risor)
  (au :BufWinEnter set-winbar)
  (au :BufReadPost :JumpToLastLocation)
  (au :BufWritePre "TrimTrailingSpace | TrimTrailingBlankLines"))
