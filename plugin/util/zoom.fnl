(local session-file (.. (vim.fn.stdpath :cache) :/zoom-session.vim))
(var zoomed? false)

(fn zoom []
  (if zoomed?
      (do
        (when (= (vim.fn.filereadable session-file) 1)
          (vim.cmd.source session-file)
          (vim.fn.delete session-file))
        (set zoomed? false))
      (let [num-windows (vim.fn.winnr :$)]
        (when (> num-windows 1)
          (vim.cmd (.. "mksession! " session-file))
          (vim.cmd.only)
          (set zoomed? true)))))

(let [com vim.api.nvim_create_user_command]
  (com :Zoom zoom {:desc "Toggle zoom for current window"}))
