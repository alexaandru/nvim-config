(local {: get} (require :mini.icons))

(fn statuscolumn []
  (let [buf (vim.api.nvim_get_current_buf)
        line (. (vim.api.nvim_buf_get_lines buf (- vim.v.lnum 1) vim.v.lnum
                                            true) 1)]
    (if (or (not line) (= line ""))
        ""
        (let [(icon hl) (get :file line)]
          (.. "%#" (or hl :WarningMsg) "#" icon "%* ")))))

(set _G.nvim_dir_statuscolumn statuscolumn)
