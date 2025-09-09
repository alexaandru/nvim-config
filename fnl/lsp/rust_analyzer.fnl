(fn reload-workspace [bufnr]
  (let [clients (vim.lsp.get_clients {: bufnr :name :rust_analyzer})]
    (each [_ client (ipairs clients)]
      (vim.notify "Reloading Cargo Workspace")
      (client:request :rust-analyzer/reloadWorkspace nil
                      (fn [err]
                        (when err (error (tostring err)))
                        (vim.notify "Cargo workspace reloaded"))
                      0))))

(fn is-library [fname]
  (let [user-home (vim.fs.normalize vim.env.HOME)
        cargo-home (or (os.getenv :CARGO_HOME) (.. user-home :/.cargo))
        registry (.. cargo-home :/registry/src)
        git-registry (.. cargo-home :/git/checkouts)
        rustup-home (or (os.getenv :RUSTUP_HOME) (.. user-home :/.rustup))
        toolchains (.. rustup-home :/toolchains)]
    (each [_ item (ipairs [toolchains registry git-registry])]
      (if (vim.fs.relpath item fname)
          (let [clients (vim.lsp.get_clients {:name :rust_analyzer})]
            (and (> (length clients) 0)
                 (. clients (length clients) :config :root_dir)))))))

;; fnlfmt: skip
(fn mk-cmd [cargo-crate-dir]
  [:cargo :metadata :--no-deps :--format-version :1 :--manifest-path (.. cargo-crate-dir :/Cargo.toml)])

;; fnlfmt: skip
(fn root_dir [bufnr on-dir]
  (let [fname (vim.api.nvim_buf_get_name bufnr)
        reused-dir (is-library fname)]
    (if reused-dir (on-dir reused-dir)
        (do
          (local cargo-crate-dir (vim.fs.root fname [:Cargo.toml]))
          (var cargo-workspace-root nil)
          (if (= cargo-crate-dir nil)
              (on-dir (or (vim.fs.root fname [:rust-project.json])
                          (vim.fs.dirname (. (vim.fs.find :.git {:path fname :upward true}) 1))))
              (let [cmd (mk-cmd cargo-crate-dir)]
                (vim.system cmd {:text true}
                            #(if (= $.code 0)
                                 (do
                                   (when $.stdout
                                     (local result (vim.json.decode $.stdout))
                                     (when (. result "workspace_root")
                                       (set cargo-workspace-root (vim.fs.normalize (. result "workspace_root")))))
                                   (on-dir (or cargo-workspace-root cargo-crate-dir)))
                                 (vim.schedule #(vim.notify (: "[rust_analyzer] cmd failed with code %d: %s %s" "format" $.code cmd $.stderr)))))))))))

(local uc vim.api.nvim_buf_create_user_command)

{:before_init (fn [init-params config]
                (when (and config.settings (. config.settings :rust-analyzer))
                  (set init-params.initializationOptions
                       (. config.settings :rust-analyzer))))
 :capabilities {:experimental {:serverStatusNotification true}}
 :cmd [:rust-analyzer]
 :filetypes [:rust]
 :on_attach #(uc $2 :LspCargoReload #(reload-workspace $2)
                 {:desc "Reload Cargo Workspace"})
 : root_dir}
