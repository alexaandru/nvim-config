(let [S {:silent true}
      SB {:silent true :buffer true}
      E {:expr true}
      T #(vim.api.nvim_replace_termcodes $ true true true)
      toggle-fold "@=((foldclosed(line('.')) < 0) ? 'zC' : 'zO')<CR>"
      syn-stack "<Cmd>echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, \"name\")')<CR>"
      lsp vim.lsp.buf
      dap (require :dap)
      dapui (require :dapui)
      widgets (require :dap.ui.widgets)
      sidebar (widgets.sidebar widgets.scopes)
      {: FnlEval : FnlCompile} (require :eval)]
  {:lsp {:n [[:gd lsp.declaration SB]
             ["<c-]>" lsp.definition SB]
             [:<F1> lsp.hover SB]
             [:gD lsp.implementation SB]
             [:<c-k> lsp.signature_help SB]
             [:1gD lsp.type_definition SB]
             [:gr lsp.references SB]
             [:g0 lsp.document_symbol SB]
             [:gW lsp.workspace_symbol SB]
             [:<F2> lsp.rename SB]
             [:<F16> lsp.code_action SB]
             [:<M-Right> vim.lsp.diagnostic.goto_next SB]
             [:<M-Left> vim.lsp.diagnostic.goto_prev SB]
             [:<F7> vim.diagnostic.setloclist SB]
             [:<Leader>k vim.lsp.codelens.run SB]]}
   :global {:n [[:gb "<Cmd>ls<CR>:b<Space>" S]
                [:db "<Cmd>%bd<bar>e#<CR>" S]
                [:<C-Enter> "<Cmd>lcd %:p:h<Bar>Term<CR>" S]
                [:<F3> #(vim.cmd :only) S]
                [:<F5> "<Cmd>GolangCI %<CR>" S]
                [:<F6> :<Cmd>RunTests<CR> S]
                [:<Leader>z dap.continue S]
                [:<Leader>b dap.toggle_breakpoint S]
                [:<Leader>o dap.step_over S]
                [:<Leader>i dap.step_into S]
                [:<Leader>x dap.step_out S]
                [:<Leader>r dap.repl.toggle S]
                [:<Leader>u dapui.toggle S]
                [:<Leader>t sidebar.toggle S]
                [:<F8> :<Cmd>Gdiff<CR> S]
                [:<Leader>w :<Cmd>SaveAndClose<CR> S]
                [:<Leader>c FnlCompile S]
                [:<Leader>e FnlEval S]
                [:<Space> toggle-fold S]
                [:Q :<Nop> S]
                [:<Esc> :<Cmd>noh<CR>]
                [:<F10> syn-stack S]]
            :v [[:<Leader>c FnlCompile S] [:<Leader>e FnlEval S]]
            :c [[:<Up> (T "wildmenumode() ? \"<Left>\" : \"<Up>\"") E]
                [:<Down> (T "wildmenumode() ? \"<Right>\" : \"<Down>\"") E]
                [:<Left> (T "wildmenumode() ? \"<Up>\" : \"<Left>\"") E]
                [:<Right> (T "wildmenumode() ? \"<BS><C-Z>\" : \"<Right>\"") E]]
            :i [["'" "''<Left>"]
                ["(" "()<Left>"]
                ["[" "[]<Left>"]
                ["{" "{}<Left>"]]}})

