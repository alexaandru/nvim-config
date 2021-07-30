{:ensure_installed :all
 :highlight {:enable true}
 :indent {:enable true}
 :incremental_selection {:enable true
                         :keymaps {:init_selection :<Return>
                                   :node_incremental :<Return>
                                   :scope_incremental :<Tab>
                                   :node_decremental :<S-Tab>}}
 :textobjects {:select {:enable true
                        :lookahead true
                        :keymaps {:af "@function.outer"
                                  :if "@function.inner"
                                  :ac "@class.outer"
                                  :ic "@class.inner"}}
               :lsp_interop {:enable true
                             :peek_definition_code {:df "@function.outer"
                                                    :dF "@class.outer"}}}}

