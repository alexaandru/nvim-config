;; Inspired by https://gitlab.com/yorickpeterse/nvim-pqf
(local type-to-sign {:E "DiagnosticSignError"
                     :W "DiagnosticSignWarn"
                     :I "DiagnosticSignInfo"
                     :N "DiagnosticSignHint"})

(fn vim.g.pqf_filter_text [info]
  (let [items (if (= info.quickfix 1)
                  (. (vim.fn.getqflist {:id info.id :items 1}) :items)
                  (. (vim.fn.getloclist info.winid {:id info.id :items 1})
                     :items))
        lines []
        type-map {:E :error :W :warning :I :info :N :hint}]
    (for [i info.start_idx info.end_idx]
      (let [item (. items i)]
        (if (and (> item.bufnr 0) (> item.lnum 0))
            (let [filepath (vim.fn.bufname item.bufnr)
                  relative-path (if (vim.startswith filepath "/")
                                    (vim.fn.fnamemodify filepath ":.")
                                    filepath)
                  type-str (if (and item.type (not= item.type ""))
                               (.. (or (. type-map item.type) item.type) ": ")
                               "")]
              (table.insert lines
                            (string.format "%s|%d col %d| %s%s" relative-path
                                           item.lnum item.col type-str item.text))))))
    lines))

(fn vim.g.pqf_add_signs [winid]
  (let [list (if winid
                 (vim.fn.getloclist winid {:items 1 :qfbufnr 1})
                 (vim.fn.getqflist {:items 1 :qfbufnr 1}))
        items list.items
        buf list.qfbufnr]
    (vim.fn.sign_unplace "pqf" {:buffer buf})
    (each [idx item (ipairs items)] ; Skip context lines (no filename or line number)
      (if (and (> item.bufnr 0) (> item.lnum 0))
          (let [sign-name (. type-to-sign item.type)]
            (if sign-name
                (vim.fn.sign_place 0 "pqf" sign-name buf
                                   {:lnum idx :priority 10})))))))

(fn delete-line []
  (let [loclist (vim.fn.getloclist 0)
        is-loclist (> (length loclist) 0)
        list (if is-loclist loclist (vim.fn.getqflist))]
    (if (> (length list) 0)
        (let [line (vim.fn.line :.)]
          (table.remove list line)
          (if is-loclist
              (vim.fn.setloclist 0 [] " " {:items list})
              (vim.fn.setqflist [] " " {:items list}))
          (let [new-count (length list)]
            (if (> new-count 0)
                (let [new-line (math.min line new-count)]
                  (vim.api.nvim_win_set_cursor 0 [new-line 0]))))))))

(fn setup []
  (vim.keymap.set :n :dd delete-line {:buffer true :silent true})
  (vim.schedule #(let [winid (vim.api.nvim_get_current_win)]
                   (if (> (length (vim.fn.getqflist)) 0)
                       (vim.g.pqf_add_signs))
                   (if (> (length (vim.fn.getloclist winid)) 0)
                       (vim.g.pqf_add_signs winid))))
  false)

(let [set-opt #(tset vim.opt $1 $2)
      au #(vim.api.nvim_create_autocmd $1 $2)
      desc "Prettify quickfix and location lists"]
  (set-opt :qftf "v:lua.vim.g.pqf_filter_text")
  (au :FileType {:pattern :qf :callback setup : desc}))
