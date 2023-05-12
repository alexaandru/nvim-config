(fn sign-in [bufnr client]
  (client:request :signIn (vim.empty_dict)
                  (fn [err result]
                    (when err (vim.notify err.message vim.log.levels.ERROR)
                      (lua "return "))
                    (when result.command
                      (local code result.userCode)
                      (local command result.command)
                      (vim.fn.setreg "+" code)
                      (vim.fn.setreg "*" code)
                      (local continue
                             (vim.fn.confirm (.. "Copied your one-time code to clipboard.
"
                                                 "Open the browser to complete the sign-in process?")
                                             "&Yes\n&No"))
                      (when (= continue 1)
                        (client:exec_cmd command {: bufnr}
                                         (fn [cmd-err cmd-result]
                                           (when cmd-err
                                             (vim.notify err.message
                                                         vim.log.levels.ERROR)
                                             (lua "return "))
                                           (when (= cmd-result.status :OK)
                                             (vim.notify (.. "Signed in as "
                                                             cmd-result.user ".")))))))
                    (if (= result.status :PromptUserDeviceFlow)
                        (vim.notify (.. "Enter your one-time code "
                                        result.userCode " in "
                                        result.verificationUri))
                        (= result.status :AlreadySignedIn)
                        (vim.notify (.. "Already signed in as " result.user "."))))))

(fn sign-out [_ client]
  (client:request :signOut (vim.empty_dict)
                  (fn [err result]
                    (when err (vim.notify err.message vim.log.levels.ERROR)
                      (lua "return "))
                    (when (= result.status :NotSignedIn)
                      (vim.notify "Not signed in.")))))

{:cmd [:copilot-language-server :--stdio]
 :filetypes [:terraform
             :hcl
             :go
             :gotmpl
             :template
             :make
             :sh
             :json
             :fennel
             :lua
             :vim
             :javascript
             :typescript
             :vue
             :python
             :scala
             :rust]
 :init_options {:editorInfo {:name :Neovim :version (tostring (vim.version))}
                :editorPluginInfo {:name :Neovim
                                   :version (tostring (vim.version))}}
 :on_attach (fn [client bufnr]
              (vim.api.nvim_buf_create_user_command bufnr :LspCopilotSignIn
                                                    (fn []
                                                      (sign-in bufnr client))
                                                    {:desc "Sign in Copilot with GitHub"})
              (vim.api.nvim_buf_create_user_command bufnr :LspCopilotSignOut
                                                    (fn []
                                                      (sign-out bufnr client))
                                                    {:desc "Sign out Copilot with GitHub"}))
 :root_markers [:.git]
 :settings {:telemetry {:telemetryLevel :all}}}
