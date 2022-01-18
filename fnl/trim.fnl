(fn kee [cmd]
  #(let [last-search (vim.fn.getreg "@/")
         start (or $.line1 :1)
         stop (or $.line2 "$")
         save (vim.fn.winsaveview)
         fmt string.format
         cmd (fmt "kee keepj keepp %s,%ss%se" start stop cmd)]
     (vim.cmd cmd)
     (vim.fn.winrestview save)
     (vim.fn.setreg "@/" last-search)))

{:TrimTrailingSpace (kee "/\\s\\+$//")
 :TrimTrailingBlankLines (kee "/\\($\\n\\s*\\)\\+\\%$//")
 :SquashBlankLines (kee "/\\(\\n\\)\\{3,}/\\1\\1/")
 :TrimBlankLines (kee "/\\(\\n\\)\\{2,}/\\1/")}

