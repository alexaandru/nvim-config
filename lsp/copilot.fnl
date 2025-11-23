(fn sign-in [bufnr client]
  (client:request :signIn (vim.empty_dict)
                  (fn [err result]
                    (if err
                        (vim.notify err.message vim.log.levels.ERROR)
                        (if result.command
                            (let [code result.userCode
                                  command result.command
                                  fy vim.notify]
                              (vim.fn.setreg "+" code)
                              (vim.fn.setreg "*" code)
                              (local continue
                                     (vim.fn.confirm (.. "Copied your one-time code to clipboard.\n"
                                                         "Open the browser to complete the sign-in process?")
                                                     "&Yes\n&No"))
                              (if (= continue 1)
                                  (client:exec_cmd command {: bufnr}
                                                   (fn [cmd-err cmd-result]
                                                     (if cmd-err
                                                         (fy err.message
                                                             vim.log.levels.ERROR))
                                                     (if (and (not cmd-err)
                                                              (= cmd-result.status
                                                                 :OK))
                                                         (fy (.. "Signed in as "
                                                                 cmd-result.user
                                                                 "."))))))))
                        (if (= result.status :PromptUserDeviceFlow)
                            (vim.notify (.. "Enter your one-time code "
                                            result.userCode " in "
                                            result.verificationUri)))
                        (if (= result.status :AlreadySignedIn)
                            (vim.notify (.. "Already signed in as " result.user
                                            ".")))))))

(fn sign-out [_ client]
  (client:request :signOut (vim.empty_dict)
                  (fn [err result]
                    (if err
                        (vim.notify err.message vim.log.levels.ERROR)
                        (when (= result.status :NotSignedIn)
                          (vim.notify "Not signed in."))))))

;; fnlfmt: skip
(let [com vim.api.nvim_buf_create_user_command]
  {:cmd [:copilot-language-server :--stdio]
   :filetypes [:terraform :hcl
               :go :gomod :gosum :gotmpl
               :template :make :sh :json :fennel :lua :vim
               :javascript :typescript :vue :python :scala :rust]
   :init_options {:editorInfo {:name :Neovim :version (tostring (vim.version))}
                  :editorPluginInfo {:name :Neovim :version (tostring (vim.version))}}
   :on_attach (fn [client bufnr]
                (com bufnr :LspCopilotSignIn #(sign-in bufnr client)
                     {:desc "Sign in Copilot with GitHub"})
                (com bufnr :LspCopilotSignOut #(sign-out bufnr client)
                     {:desc "Sign out Copilot with GitHub"}))
   :root_markers [:.git]
   :settings {:telemetry {:telemetryLevel :all}}})
