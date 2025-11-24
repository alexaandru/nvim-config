
;; fnlfmt: skip
(let [providers [:python3 :node :ruby :perl]
      builtin [:2html_plugin :man :netrw
               :remote_file_loader :remote_plugins
               :tutor_mode_plugin :tarPlugin :zipPlugin]
      providers (vim.iter providers)
      builtin (vim.iter builtin)]
  (providers:each #(tset vim.g (.. :loaded_ $ :_provider) 0))
  (builtin:each #(tset vim.g (.. :loaded_ $) 1)))
