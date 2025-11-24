(fn LspCapabilities []
  (vim.notify (vim.inspect (collect [_ c (pairs (vim.lsp.get_clients {:buffer 0}))]
                             c.name
                             (collect [k v (pairs c.server_capabilities)]
                               (if v (values k v)))))))

(fn LastWindow []
  (fn is-quittable []
    (let [{:buftype bt :filetype ft} (vim.fn.getbufvar "%" "&")]
      (or (vim.tbl_contains [:quickfix :terminal :nofile] bt) (= ft :netrw))))

  (fn last-window []
    (= -1 (vim.fn.winbufnr 2)))

  (if (and (is-quittable) (last-window))
      (vim.cmd "norm ZQ")))

(fn LspHintsToggle []
  (if vim.b.hints_on
      (let [x (not vim.b.hints)]
        (set vim.b.hints x)
        (vim.lsp.inlay_hint.enable x {:bufnr 0}))))

(fn SetProjRoot []
  (if (not vim.w.proj_root)
      (let [cmd "git rev-parse --show-toplevel"
            root (-> (vim.fn.system cmd)
                     (: :gsub "\n$" ""))
            root (if (= vim.v.shell_error 0) root ".")]
        (set vim.w.proj_root root))))

(fn BuiltinPacks []
  (let [result []
        all-opt (vim.fn.globpath vim.o.packpath "pack/*/opt/*" true true)
        all-start (vim.fn.globpath vim.o.packpath "plugin/*" true true)]
    (each [_ path (ipairs all-opt)]
      (when (path:match "^/tmp/%.mount_nvim")
        (table.insert result (.. "opt:" (vim.fs.basename path)))))
    (each [_ path (ipairs all-start)]
      (when (path:match "^/tmp/%.mount_nvim")
        (table.insert result (vim.fs.basename path))))
    (print (vim.inspect result))))

(let [cmd vim.api.nvim_create_user_command]
  (cmd :Gdiff "Gitsigns diffthis"
       {:desc "Git diff against another branch"})
  (cmd :Grep "sil grep <args>"
       {:bar true :nargs 1 :desc "Search using git grep"})
  ;; https://github.com/neovim/neovim/issues/34764#issuecomment-3543397752
  (cmd :PackUpdate #(vim.pack.update) {:desc "Update all packages"})
  (cmd :Term "12split | term <args>"
       {:nargs "*" :desc "Open terminal in split"})
  (cmd :SetProjRoot SetProjRoot {:bar true :desc "Set project root directory"})
  (cmd :CdProjRoot "SetProjRoot | cd `=w:proj_root`"
       {:desc "Change to project root"})
  (cmd :JumpToLastLocation
       "let b:pos = line('''\"') | if b:pos && b:pos <= line('$') | exe b:pos | endif"
       {:desc "Jump to last cursor position"})
  (cmd :SaveAndClose "up | bdel" {:desc "Save and close buffer"})
  (cmd :LastWindow LastWindow {:bar true :desc "Close if last window"})
  (cmd :Scratchify "setl nobl bt=nofile bh=delete noswf"
       {:bar true :desc "Make buffer a scratch buffer"})
  (cmd :Scratch "<mods> new +Scratchify"
       {:bar true :desc "Create new scratch buffer"})
  (cmd :AutoWinHeight "sil exe max([min([line('$')+1, 16]), 1]).'wincmd _'"
       {:bar true :desc "Auto-adjust window height"})
  (cmd :LspCapabilities LspCapabilities {:desc "Show LSP server capabilities"})
  (cmd :LspHintsToggle LspHintsToggle {:desc "Toggle LSP inlay hints"})
  (cmd :BuiltinPacks BuiltinPacks {:desc "Show builtin packages"})
  (cmd :JQ "<line1>,<line2>!jq -S ."
       {:range true :bar true :desc "Format JSON with jq"}))
