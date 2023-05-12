{:keymap {:preset :enter}
 :fuzzy {:implementation :lua}
 :signature {:enabled true}
 :completion {:list {:selection {:preselect true :auto_insert true}}
              ; preselect,manual,auto_insert
              :ghost_text {:enabled true}
              :documentation {:auto_show true :auto_show_delay_ms 500}
              :menu {:auto_show true
                     ;:auto_show #(not= $.mode :cmdline)
                     :draw {:treesitter []}}}}
