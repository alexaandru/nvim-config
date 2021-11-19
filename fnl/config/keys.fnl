(let [S {:silent true}
      E {:expr true}
      T #(vim.api.nvim_replace_termcodes $ true true true)]
  {:lsp {:buf {:declaration :gd
               :definition "<c-]>"
               :hover :<F1>
               :implementation :gD
               :signature_help :<c-k>
               :type_definition :1gD
               :references :gr
               :document_symbol :g0
               :workspace_symbol :gW
               :rename :<F2>
               :code_action :<F16>}
         :diagnostic {:goto_next :<M-Right>
                      :goto_prev :<M-Left>
                      :setloclist :<F7>}
         :codelens {:run :<Leader>k}}
   :global {:n [[:gb "<Cmd>ls<CR>:b<Space>" S]
                [:db "<Cmd>%bd<bar>e#<CR>" S]
                [:<C-n> "<Cmd>let $CD=expand('%:p:h')<CR><Cmd>Term<CR>cd \"$CD\"<CR>clear<CR>" S]
                [:<F3> :<Cmd>only<CR> S]
                [:<F5> "<Cmd>lua GolangCI()<CR>" S]
                [:<F6> "<Cmd>lua RunTests()<CR>" S]
                [:<F8> :<Cmd>Gdiff<CR> S]
                [:<Leader>w :<Cmd>SaveAndClose<CR> S]
                [:<Leader>c :<Cmd>FnlCompile<CR> S]
                [:<Leader>e :<Cmd>FnlEval<CR> S]
                [:<Space> "@=((foldclosed(line('.')) < 0) ? 'zC' : 'zO')<CR>" S]
                [:Q :<Nop> S]
                [:<Esc> :<Cmd>noh<CR>]
                [:<F10> "<Cmd>echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, \"name\")')<CR>" S]]
            :c [[:<Up> (T "wildmenumode() ? \"<Left>\" : \"<Up>\"") E]
                [:<Down> (T "wildmenumode() ? \"<Right>\" : \"<Down>\"") E]
                [:<Left> (T "wildmenumode() ? \"<Up>\" : \"<Left>\"") E]
                [:<Right> (T "wildmenumode() ? \"<BS><C-Z>\" : \"<Right>\"") E]]
            :i [[:<Tab> "luaeval('SmartTabComplete()')" E]
                [:<C-x>m "<C-r>=v:lua.Compe()<CR>" S]
                ["'" "''<Left>"]
                ["(" "()<Left>"]
                ["[" "[]<Left>"]
                ["{" "{}<Left>"]]}})

