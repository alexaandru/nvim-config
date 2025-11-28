(fn LspCapabilities []
  (vim.print (collect [_ c (pairs (vim.lsp.get_clients {:buffer 0}))]
               c.name
               (collect [k v (pairs c.server_capabilities)]
                 (if v (values k v))))))

; TODO: add back :nofile but with selective support for
; acwrite buftype. The only catch is, that one is also nofile
; on enter, the bt gets set later. It also the last/only window
; in that tab, since it opens in a new tab by default.
(fn LastWindow []
  (let [bt vim.bo.buftype
        is-quittable (vim.tbl_contains [:quickfix :terminal] bt)
        last-window (= 1 (vim.fn.winnr :$))]
    (if (and is-quittable last-window)
        (vim.cmd "norm ZQ"))))

(fn LspHintsToggle []
  (if vim.b.hints_on
      (let [x (not vim.b.hints)]
        (set vim.b.hints x)
        (vim.lsp.inlay_hint.enable x {:bufnr 0}))))

(fn SetProjRoot []
  (if (not vim.w.proj_root)
      (let [file-dir (vim.fn.expand "%:p:h")
            rev-p " rev-parse --show-toplevel"
            cmd (.. "git -C " (vim.fn.shellescape file-dir) rev-p)
            root (-> (vim.fn.system cmd)
                     (: :gsub "\n$" ""))
            root (if (= vim.v.shell_error 0) root file-dir)]
        (set vim.w.proj_root root))))

(fn BuiltinPacks []
  (let [result []
        all-opt (vim.fn.globpath vim.o.packpath "pack/*/opt/*" true true)
        all-start (vim.fn.globpath vim.o.packpath "plugin/**/*" true true)
        root "^/tmp/%.mount_nvim"]
    (each [_ path (ipairs all-opt)]
      (if (path:match root)
          (table.insert result (.. "opt:" (vim.fs.basename path)))))
    (each [_ path (ipairs all-start)]
      (if (and (path:match root) (= (vim.fn.isdirectory path) 0))
          (table.insert result (vim.fs.basename path))))
    (vim.print result)))

(fn Version []
  (let [nvim-version (-> (vim.fn.execute "version")
                         (: :gsub "^\n" "")
                         (: :gsub "\n[^\n]*$" ""))
        lines [nvim-version]]
    (if vim.g.neovide
        (table.insert lines (.. "Neovide v" vim.g.neovide_version)))
    (let [config-path (vim.fn.stdpath "config")
          cmd "scc --include-ext fnl --exclude-dir lsp --format json "
          cmd (.. cmd (vim.fn.shellescape config-path))
          json (vim.fn.system cmd)
          data (vim.fn.json_decode json)
          loc (. (. data 1) :Code)
          lsps (length (vim.tbl_keys vim.lsp.config._configs))
          packs (length (vim.tbl_keys (vim.pack.get)))
          tpl "%dLOC .fnl, %d LSPs, %d plugins"]
      (table.insert lines (tpl:format loc lsps packs)))
    (print (table.concat lines "\n"))))

(let [opts #(vim.tbl_extend :force {:desc $} (or $2 {}))
      cmd #(vim.api.nvim_create_user_command $ $2 (opts $3 $4))]
  (cmd :Gdiff "Gitsigns diffthis" "Git diff against another branch")
  (cmd :Grep "sil grep <args>" "Search using git grep" {:bar true :nargs 1})
  ;; https://github.com/neovim/neovim/issues/34764#issuecomment-3543397752
  (cmd :PackUpdate #(vim.pack.update) "Update all packages")
  (cmd :Term "12split | term <args>" "Open terminal in split" {:nargs "*"})
  (cmd :SetProjRoot SetProjRoot "Set project root directory" {:bar true})
  (cmd :CdProjRoot "SetProjRoot | cd `=w:proj_root`" "Change to project root")
  (cmd :JumpToLastLocation
       "let b:pos = line('''\"') | if b:pos && b:pos <= line('$') | exe b:pos | endif"
       "Jump to last cursor position")
  (cmd :SaveAndClose "up | bdel" "Save and close buffer")
  (cmd :LastWindow LastWindow "Close if last window" {:bar true})
  (cmd :Scratchify "setl nobl bt=nofile bh=delete noswf"
       "Make buffer a scratch buffer" {:bar true})
  (cmd :Scratch "<mods> new +Scratchify" "Create new scratch buffer"
       {:bar true})
  (cmd :AutoWinHeight "sil exe max([min([line('$')+1, 16]), 1]).'wincmd _'"
       "Auto-adjust window height" {:bar true})
  (cmd :LspCapabilities LspCapabilities "Show LSP server capabilities")
  (cmd :LspHintsToggle LspHintsToggle "Toggle LSP inlay hints")
  (cmd :BuiltinPacks BuiltinPacks "Show builtin packages")
  (cmd :Version Version "Show Neovim and Neovide versions")
  (cmd :JQ "<line1>,<line2>!jq -S ." "Format JSON with jq"
       {:range true :bar true}))
