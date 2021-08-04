(fn kee [cmd]
  #(let [last-search (vim.fn.getreg "@/")
         start (or $1 :1)
         stop (or $2 "$")
         save (vim.fn.winsaveview)
         fmt string.format
         cmd (fmt "kee keepj keepp %s,%ss%se" start stop cmd)]
     (vim.cmd cmd)
     (vim.fn.winrestview save)
     (vim.fn.setreg "@/" last-search)))

(let [commands {:TrimTrailingSpace "/\\s\\+$//"
                :TrimTrailingBlankLines "/\\($\\n\\s*\\)\\+\\%$//"
                :SquashBlankLines "/\\(\\n\\)\\{3,}/\\1\\1/"
                :TrimBlankLines "/\\(\\n\\)\\{2,}/\\1/"}]
  (each [k v (pairs commands)]
    (tset _G k (kee v))))

