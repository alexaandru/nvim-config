{:Setup [; Pattern is <event>,
         ; <command_or_callback>,  // command if string, callback if function
         ; [, <buffer_or_pattern>] // buffer if numeric, pattern if string, defaults to "*"
         [[:VimEnter :DirChanged] "exe 'LoadLocalCfg' | lua GitStatus()"]
         [[:WinNew :WinEnter] "lua GitStatus()"]
         [:TextYankPost "sil! lua vim.highlight.on_yank()"]
         [:QuickFixCmdPost :cw "[^l]*"]
         [:QuickFixCmdPost :lw :l*]
         [:TermOpen :star]
         [:TermClose :q]
         [:FileType :AutoWinHeight :qf]
         [:FileType "setl spell spl=en_us" "gitcommit,asciidoc,markdown"]
         [:FileType "setl ts=2 sw=2 sts=2 fdls=0" "lua,vim"]
         [:FileType "setl ts=4 sw=4 noet cole=1" :go]
         [:BufEnter "exe 'ColorizerAttachToBuffer' | LastWindow"]
         [:BufEnter "setl ft=nginx" :nginx/*]
         [:BufEnter "setl ft=gomod" :go.mod]
         [:BufReadPost :JumpToLastLocation]
         [:BufWritePre "TrimTrailingSpace | TrimTrailingBlankLines" :*.txt]
         [:BufWritePre :AutoIndent :*.vim]]}

