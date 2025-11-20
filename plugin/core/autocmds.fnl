(fn LoadLocalCfg []
  (if (= 1 (vim.fn.filereadable :.nvimrc))
      (vim.cmd "so .nvimrc")))

(fn LspHintsToggle [val]
  (if vim.b.hints_on (vim.lsp.inlay_hint.enable val {:bufnr 0})))

(fn QfDelete []
  (let [qflist (vim.fn.getqflist)]
    (if (> (length qflist) 0)
        (let [line (vim.fn.line :.)]
          (table.remove qflist line)
          (vim.fn.setqflist [] " " {:items qflist})
          (let [new-count (length qflist)]
            (if (> new-count 0)
                (let [new-line (math.min line new-count)]
                  (vim.api.nvim_win_set_cursor 0 [new-line 0]))))))))

(fn FormatBuffer []
  (let [view (vim.fn.winsaveview)]
    (vim.cmd "silent! norm ggVGgq")
    (vim.fn.winrestview view)
    (vim.schedule #(vim.cmd "norm zR"))
    false))

(fn FormatJson []
  (let [lines (vim.api.nvim_buf_get_lines 0 0 -1 false)
        output (vim.fn.systemlist "jq ." lines)]
    (if (= vim.v.shell_error 0)
        (vim.api.nvim_buf_set_lines 0 0 -1 false output))
    false))

;; fnlfmt: skip
(local compat-format [:*.fnl :*.d2 :*.md
                      :*.js :*.ts :*.vue
                      :*.yaml :*.yml :*.html :*.scss :*.css])

(let [setup (vim.api.nvim_create_augroup :Setup {:clear true})
      au #(vim.api.nvim_create_autocmd $1 (doto $2 (tset :group setup)))
      nmap #(vim.keymap.set :n $1 $2 $3)]
  (au [:VimEnter :DirChanged] {:callback LoadLocalCfg})
  (au :VimEnter {:command :CdProjRoot})
  (au :VimResized {:command "wincmd ="})
  (au :InsertEnter {:callback #(LspHintsToggle false)})
  (au :InsertLeave {:callback #(LspHintsToggle (not= false vim.b.hints))})
  (au :TextYankPost {:callback #(vim.hl.on_yank {:timeout 450})})
  (au :QuickFixCmdPost {:command :cw :pattern "[^l]*"})
  (au :QuickFixCmdPost {:command :lw :pattern :l*})
  (au :TermOpen {:command :star})
  (au :TermClose {:command :q})
  (au :FileType {:command "wincmd L" :pattern :help})
  (au :FileType {:command :AutoWinHeight :pattern :qf})
  (au :FileType {:command "setl cul" :pattern :qf})
  (au :FileType
      {:pattern :qf
       :callback #(nmap :dd QfDelete {:buffer $.buf :silent true})})
  (au :FileType {:command "setl spell spl=en_us"
                 :pattern "gitcommit,asciidoc,markdown"})
  (au :FileType {:command "setl ts=2 sw=2 sts=2 fdls=0"
                 :pattern "lua,vim,zsh,sh"})
  (au :FileType {:command "setl ts=4 sw=4 noet cole=1" :pattern :go})
  ;; https://www.reddit.com/r/neovim/comments/1oxgrnx/enabling_treesitter_highlighting_if_its_installed/
  (au :FileType {:callback #(let [_ (pcall vim.treesitter.start)]
                              false)})
  (au :BufEnter {:command :LastWindow})
  (au :BufEnter {:command "setl ft=nginx" :pattern :nginx/*})
  (au :BufEnter {:command "setl ft=risor" :pattern :*.risor})
  (au :BufEnter {:command :startinsert :pattern :dap-repl})
  (au :BufReadPost {:command :JumpToLastLocation})
  (au :BufWritePre {:command "TrimTrailingSpace | TrimTrailingBlankLines"
                    :pattern :*.txt})
  (au :BufWritePre {:callback FormatJson :pattern :*.json})
  (au :FileType {:command "setl fp=fnlfmt\\ -" :pattern :fennel})
  (au :FileType {:command "setl fp=d2\\ fmt\\ -" :pattern :d2})
  (au :FileType
      {:pattern [:javascript :typescript :vue]
       :callback #(set vim.bo.formatprg
                       "prettier --no-semi --stdin-filepath=% | eslint_d --fix-to-stdout --stdin --stdin-filename=%")})
  (au :FileType {:command "setl fp=prettier\\ --stdin-filepath=%"
                 :pattern [:yaml :html :scss :css]})
  ;; Due to site-util marking certain .txt files as markdown we need pass the parser.
  (au :FileType {:command "setl fp=prettier\\ --parser\\ markdown\\ --stdin-filepath=%"
                 :pattern :markdown})
  (au :BufWritePre {:callback FormatBuffer :pattern compat-format}))
