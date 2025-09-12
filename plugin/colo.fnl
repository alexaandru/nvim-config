;; Get all available colorschemes
(fn get-colorschemes []
  (let [schemes (vim.fn.getcompletion "" :color)]
    (table.sort schemes)
    schemes))

;; Get current colorscheme index in the list
(fn get-current-index [schemes]
  (let [current (or vim.g.colors_name :default)]
    (var idx 1)
    (each [i scheme (ipairs schemes)]
      (when (= scheme current)
        (set idx i)))
    idx))

;; Make background transparent
(fn make-transparent []
  (vim.api.nvim_set_hl 0 :Normal {:bg :NONE})
  (vim.api.nvim_set_hl 0 :NormalFloat {:bg :NONE})
  (vim.api.nvim_set_hl 0 :NormalNC {:bg :NONE})
  (vim.api.nvim_set_hl 0 :SignColumn {:bg :NONE})
  (vim.api.nvim_set_hl 0 :EndOfBuffer {:bg :NONE})
  (vim.api.nvim_set_hl 0 :Folded {:bg :NONE :link :Comment})
  (vim.api.nvim_set_hl 0 :PmenuMatch {:fg :Red})
  (vim.api.nvim_set_hl 0 :PmenuSel {:fg :#CC2666 :bold true :bg :#222232})
  (vim.api.nvim_set_hl 0 :BlinkCmpLabelMatch {:fg :#CC2666 :bold true})
  (vim.api.nvim_set_hl 0 :Comment {:fg :#444464}))

;; Set colorscheme and handle froggy integration
(fn set-colorscheme [scheme]
  (vim.cmd.colorscheme scheme)
  (make-transparent))

;; Cycle to next colorscheme
(fn cycle-next []
  (let [schemes (get-colorschemes)
        scheme-count (length schemes)]
    (when (> scheme-count 0)
      (let [current-idx (get-current-index schemes)
            next-idx (if (= current-idx scheme-count) 1 (+ current-idx 1))
            next-scheme (. schemes next-idx)]
        (set-colorscheme next-scheme)
        (print (.. "🎨 " next-scheme " (" next-idx "/" scheme-count ")"))))))

;; Cycle to previous colorscheme
(fn cycle-prev []
  (let [schemes (get-colorschemes)
        scheme-count (length schemes)]
    (when (> scheme-count 0)
      (let [current-idx (get-current-index schemes)
            prev-idx (if (= current-idx 1) scheme-count (- current-idx 1))
            prev-scheme (. schemes prev-idx)]
        (set-colorscheme prev-scheme)
        (print (.. "🎨 " prev-scheme " (" prev-idx "/" scheme-count ")"))))))

;; Show current colorscheme info
(fn show-current []
  (let [schemes (get-colorschemes)
        current-idx (get-current-index schemes)
        current (or vim.g.colors_name :default)]
    (print (.. "🎨 Current: " current " (" current-idx "/" (length schemes)
               ")"))))

;; List all available colorschemes
(fn list-all []
  (let [schemes (get-colorschemes)
        current (or vim.g.colors_name :default)]
    (print "🎨 Available colorschemes:")
    (each [_ scheme (ipairs schemes)]
      (let [marker (if (= scheme current) "→ " "  ")]
        (print (.. marker scheme))))))

;; Set a specific colorscheme by name with completion
(fn set-by-name [args]
  (let [scheme (. args :args)]
    (if (and scheme (not= scheme ""))
        (do
          (set-colorscheme scheme)
          (print (.. "🎨 Set to: " scheme)))
        (list-all))))

;; Create user commands
(vim.api.nvim_create_user_command :ColorNext cycle-next
                                  {:desc "Cycle to next colorscheme"})

(vim.api.nvim_create_user_command :ColorPrev cycle-prev
                                  {:desc "Cycle to previous colorscheme"})

(vim.api.nvim_create_user_command :ColorCurrent show-current
                                  {:desc "Show current colorscheme info"})

(vim.api.nvim_create_user_command :ColorList list-all
                                  {:desc "List all available colorschemes"})

(vim.api.nvim_create_user_command :ColorSet set-by-name
                                  {:nargs "?"
                                   :complete :color
                                   :desc "Set colorscheme by name"})

;; Set up autocmd to make background transparent on any colorscheme change
(vim.api.nvim_create_autocmd :ColorScheme
                             {:pattern "*"
                              :callback make-transparent
                              :desc "Make background transparent after colorscheme change"})

;; Set up keymaps (following your existing patterns)
(local {: map} (require :setup))

(map {:n [;; F12 for next, Shift+F12 for previous
          [:<F12> :<Cmd>ColorNext<CR> {:silent true :desc "Next colorscheme"}]
          [:<S-F12>
           :<Cmd>ColorPrev<CR>
           {:silent true :desc "Previous colorscheme"}]
          ;; Leader mappings following your pattern
          [:<Leader>cn
           :<Cmd>ColorNext<CR>
           {:silent true :desc "Next colorscheme"}]
          [:<Leader>cp
           :<Cmd>ColorPrev<CR>
           {:silent true :desc "Previous colorscheme"}]
          [:<Leader>cc
           :<Cmd>ColorCurrent<CR>
           {:silent true :desc "Show current colorscheme"}]
          [:<Leader>cl
           :<Cmd>ColorList<CR>
           {:silent true :desc "List colorschemes"}]
          [:<Leader>cs ":ColorSet " {:desc "Set colorscheme"}]]})
