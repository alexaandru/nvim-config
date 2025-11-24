(local opts {:cursor_animation_length 0.00
             :cursor_trail_size 0
             :cursor_animate_in_insert_mode false
             :cursor_animate_command_line false
             :scroll_animation_far_lines 0
             :scroll_animation_length 0.00
             :padding_top 10
             :padding_bottom 0
             :padding_right 5
             :padding_left 0
             :opacity 0.98
             :confirm_quit false
             :hide_mouse_when_typing true})

(when vim.g.neovide
  (set vim.g.transparency 0)
  (set opts.normal_opacity opts.opacity)
  (let [opts (vim.iter opts)
        n :neovide_]
    (opts:each #(tset vim.g (.. n $) $2))))
