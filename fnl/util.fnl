;; inspired by https://vim.fandom.com/wiki/Smart_mapping_for_tab_completion
(fn _G.SmartTabComplete []
  (let [line (vim.fn.getline ".")
        col (vim.fn.col ".")
        ch (line:sub (- col 1) col)
        ch (if (line:match "/") "/" ch)
        t #(vim.api.nvim_replace_termcodes $ true true true)
        default (if (= vim.bo.omnifunc "") :<C-x><C-n> :<C-x><C-o>)]
    (t (match ch
         "" :<Tab>
         " " :<Tab>
         "\t" :<Tab>
         "/" :<C-x><C-f>
         _ default))))

;; https://www.youtube.com/watch?v=NUr-VvaOEHQ
(fn _G.Compe []
  ;(print (vim.inspect (vim.lsp.buf.completion)))
  (let [words [:hello :world]]
    (vim.fn.complete (vim.fn.col ".") words))
  "")

(fn _G.GitStatus []
  (let [branch (vim.trim (vim.fn.system "git rev-parse --abbrev-ref HEAD 2> /dev/null"))]
    (if (not= branch "")
        (let [dirty (.. (vim.fn.system "git diff --quiet || echo -n \\*")
                        (vim.fn.system "git diff --cached --quiet || echo -n \\+"))]
          (set vim.w.git_status (.. branch dirty))))))

(fn _G.ProjRelativePath []
  (string.sub (vim.fn.expand "%:p") (+ (length vim.w.proj_root) 1)))

nil

