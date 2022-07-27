;; TODO:
;; - configurable API endpoint and default method+verb
;; - overrideable endpoint,method,verb (via config as well as via params to a command/function TBD)
;; - autostart API server
;; - run the API call async
;; - display errors
;; - ability to run from files other than JSON (use treesitter to detect if we're in a JSON object)
;; - autoselect outermost json object?
;; - add buf local autocommand to rerun on save

(local {: get-selection} (require :util))

(fn api []
  (when (vim.tbl_contains [:json :markdown] vim.bo.filetype)
    (let [json (get-selection)
          f (assert (io.open :/tmp/api.json :w))]
      (assert (f:write json))
      (assert (f:flush))
      (assert (f:close)))
    (when (not vim.g.api)
      (set vim.g.api (vim.api.nvim_create_buf false true))
      (vim.api.nvim_buf_set_option vim.g.api :filetype :json))
    (let [cmd vim.cmd
          out (vim.fn.system [:curl
                              :-sd
                              "@/tmp/api.json"
                              "localhost:5000/query"])
          wnum (vim.fn.bufwinnr vim.g.api)
          jump-or-split (if (= -1 wnum) (.. :vs|b vim.g.api)
                            (.. wnum "wincmd w"))]
      (vim.api.nvim_buf_set_lines vim.g.api 0 -1 false [out])
      (cmd jump-or-split)
      (cmd "setl nofoldenable")
      (cmd :JQ)
      (vim.fn.setpos "." [0 0 0 0]))))

(each [_ mode (ipairs [:n :v])]
  (vim.keymap.set mode :<Leader>q api {:silent true}))

