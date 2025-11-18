(let [providers [:python3 :node :ruby :perl]
      builtin [:2html_plugin :man :netrw
               :remote_file_loader :remote_plugins
               :tutor_mode_plugin :tarPlugin :zipPlugin]]
  (vim.tbl_map #(tset vim.g (.. :loaded_ $ :_provider) 0) providers)
  (vim.tbl_map #(tset vim.g (.. :loaded_ $) 1) builtin))
