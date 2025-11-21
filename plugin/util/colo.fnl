(fn get-colorschemes []
  (let [schemes (vim.fn.getcompletion "" :color)]
    (table.sort schemes)
    schemes))

(fn get-current-index [schemes]
  (let [current (or vim.g.colors_name :default)]
    (var idx 1)
    (each [i scheme (ipairs schemes)]
      (if (= scheme current) (set idx i)))
    idx))

(fn set-colorscheme [scheme]
  (vim.cmd.colorscheme scheme))

(fn cycle-next []
  (let [schemes (get-colorschemes)
        scheme-count (length schemes)]
    (if (> scheme-count 0)
        (let [current-idx (get-current-index schemes)
              next-idx (if (= current-idx scheme-count) 1 (+ current-idx 1))
              next-scheme (. schemes next-idx)]
          (set-colorscheme next-scheme)
          (print (.. "🎨 " next-scheme " (" next-idx "/" scheme-count ")"))))))

(fn cycle-prev []
  (let [schemes (get-colorschemes)
        scheme-count (length schemes)]
    (if (> scheme-count 0)
        (let [current-idx (get-current-index schemes)
              prev-idx (if (= current-idx 1) scheme-count (- current-idx 1))
              prev-scheme (. schemes prev-idx)]
          (set-colorscheme prev-scheme)
          (print (.. "🎨 " prev-scheme " (" prev-idx "/" scheme-count ")"))))))

(fn show-current []
  (let [schemes (get-colorschemes)
        current-idx (get-current-index schemes)
        current (or vim.g.colors_name :default)]
    (print (.. "🎨 Current: " current " (" current-idx "/" (length schemes)
               ")"))))

(fn list-all []
  (let [schemes (get-colorschemes)
        current (or vim.g.colors_name :default)]
    (print "🎨 Available colorschemes:")
    (each [_ scheme (ipairs schemes)]
      (let [marker (if (= scheme current) "→ " "  ")]
        (print (.. marker scheme))))))

(fn set-by-name [args]
  (let [scheme (. args :args)]
    (if (and scheme (not= scheme ""))
        (do
          (set-colorscheme scheme)
          (print (.. "🎨 Set to: " scheme)))
        (list-all))))

(let [com vim.api.nvim_create_user_command
      nmap #(vim.keymap.set :n $1 $2 $3)]
  (com :ColorNext cycle-next {:desc "Cycle to next colorscheme"})
  (com :ColorPrev cycle-prev {:desc "Cycle to previous colorscheme"})
  (com :ColorCurrent show-current {:desc "Show current colorscheme info"})
  (com :ColorList list-all {:desc "List all available colorschemes"})
  (com :ColorSet set-by-name
       {:nargs "?" :complete :color :desc "Set colorscheme by name"})
  (nmap :<F12> :<Cmd>ColorNext<CR> {:silent true :desc "Next colorscheme"})
  (nmap :<S-F12> :<Cmd>ColorPrev<CR>
        {:silent true :desc "Previous colorscheme"})
  (nmap :<Leader>cn :<Cmd>ColorNext<CR> {:silent true :desc "Next colorscheme"})
  (nmap :<Leader>cp :<Cmd>ColorPrev<CR>
        {:silent true :desc "Previous colorscheme"})
  (nmap :<Leader>cc :<Cmd>ColorCurrent<CR>
        {:silent true :desc "Show current colorscheme"})
  (nmap :<Leader>cl :<Cmd>ColorList<CR>
        {:silent true :desc "List colorschemes"})
  (nmap :<Leader>cs ":ColorSet " {:desc "Set colorscheme"}))
