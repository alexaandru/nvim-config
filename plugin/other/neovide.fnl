(local opts {:cursor_animation_length 0.100
             :cursor_trail_size 0.5
             :cursor_animate_in_insert_mode true
             :cursor_animate_command_line true
             :scroll_animation_far_lines 10
             :scroll_animation_length 0.100
             :padding_top 10
             :padding_bottom 0
             :padding_right 5
             :padding_left 0
             :progress_bar_enabled true
             :progress_bar_height 3.0
             :progress_bar_animation_speed 150.0
             :progress_bar_hide_delay 1.0
             :opacity 0.98
             :confirm_quit false
             :hide_mouse_when_typing true})

(when vim.g.neovide
  (set vim.g.transparency 0)
  (set opts.normal_opacity opts.opacity)
  (let [opts (vim.iter opts)
        n :neovide_]
    (opts:each #(tset vim.g (.. n $) $2))))
