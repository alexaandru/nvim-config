{:cmd [:hyprls :--stdio]
 :filetypes [:hyprlang]
 :root-dir-fn (fn [filename]
                (or (filename:match "(.*/hypr)/")
                    (vim.fs.dirname filename)))}
