(local {: !providers : !builtin : setup : r
        : au : lēt : opt : com : map : colo} (require :setup))

(!providers [:python3 :node :ruby :perl])
(!builtin [:2html_plugin :man :matchit :netrwPlugin
           :tutor_mode_plugin :tarPlugin :zipPlugin])

(lēt (r :vars))
(opt (r :options))
(au {:Setup (r :autocmd)})
(com (r :commands))
(map (r :keys))

(setup :lsp :treesitter :pqf ; TODO: lazy load these
       :dap-go :nvim-dap-virtual-text :dapui)

(colo :smurfs)

