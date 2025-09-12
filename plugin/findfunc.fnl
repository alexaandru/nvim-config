(fn findfunc [cmdarg _cmdcomplete]
  (let [cmd "fd -t f --hidden --color=never --max-depth 10"
        fd-output (vim.fn.systemlist cmd)]
    (if (= (length cmdarg) 0)
        fd-output
        (vim.fn.matchfuzzy fd-output cmdarg {:matchseq 1 :key "tail"}))))

(when (= (vim.fn.executable :fd) 1)
  (set _G.Fd_findfunc findfunc)
  (set vim.o.findfunc "v:lua.Fd_findfunc"))
