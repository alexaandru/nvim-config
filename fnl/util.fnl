(local wait-default 2000)

(fn _G.Format [wait-ms]
  (vim.lsp.buf.formatting_sync nil (or wait-ms wait-default)))

;; Synchronously organise imports, courtesy of
;; https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-656372575 and
;; https://github.com/lucax88x/configs/blob/master/dotfiles/.config/nvim/lua/lt/lsp/functions.lua
(fn _G.OrgImports [wait-ms]
  (let [params (vim.lsp.util.make_range_params)]
    (set params.context {:only [:source.organizeImports]})
    (let [result (vim.lsp.buf_request_sync 0 :textDocument/codeAction params
                                           (or wait-ms wait-default))]
      (each [_ res (pairs (or result {}))]
        (each [_ r (pairs (or res.result {}))]
          (if r.edit
              (vim.lsp.util.apply_workspace_edit r.edit vim.b.offset_encoding)
              (vim.lsp.buf.execute_command r.command)))))))

(fn _G.OrgJSImports []
  (vim.lsp.buf.execute_command {:arguments [(vim.fn.expand "%:p")]
                                :command :_typescript.organizeImports}))

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

(fn _G.Lightbulb []
  (let [{: update_lightbulb} (require :nvim-lightbulb)]
    (update_lightbulb {:sign {:enabled false}
                       :virtual_text {:enabled true :text "💡"}})))

nil

