(local aux {:VimHighlightOnYank #(vim.highlight.on_yank)
            :LoadLocalCfg #(if (= 1 (vim.fn.filereadable :.nvimrc))
                               (vim.cmd "so .nvimrc"))})

(fn cb [events name pat]
  (let [cb (. aux name)
        desc (.. name "()")]
    [events cb pat desc]))

(fn aux.GitStatus []
  (let [git #(vim.fn.system (.. "git " $))
        branch (vim.trim (git "rev-parse --abbrev-ref HEAD 2> /dev/null"))]
    (if (not= branch "")
        (let [dirty (.. (git "diff --quiet || echo -n \\*")
                        (git "diff --cached --quiet || echo -n \\+"))]
          (set vim.w.git_status (.. branch dirty))))))

;; Format is: [<item>], where each <item> is itself a list of:
;;
;; <event>,                // event type (string or list)
;; <command_or_callback>,  // command (string) or callback (function)
;; [, <buffer_or_pattern>  // buffer (number) or pattern (string), default is "*"
;;  [, <desc>]]            // callback description

[(cb [:VimEnter :DirChanged] :LoadLocalCfg)
 (cb [:VimEnter :DirChanged :WinNew :WinEnter] :GitStatus)
 (cb :TextYankPost :VimHighlightOnYank)
 [:QuickFixCmdPost :cw "[^l]*"]
 [:QuickFixCmdPost :lw :l*]
 [:TermOpen :star]
 [:TermClose :q]
 [:FileType :AutoWinHeight :qf]
 [:FileType "setl cul" :qf]
 [:FileType "setl spell spl=en_us" "gitcommit,asciidoc,markdown"]
 [:FileType "setl ts=2 sw=2 sts=2 fdls=0" "lua,vim"]
 [:FileType "setl ts=4 sw=4 noet cole=1" :go]
 [:BufEnter "exe 'ColorizerAttachToBuffer' | LastWindow"]
 [:BufEnter "setl ft=nginx" :nginx/*]
 [:BufEnter "setl ft=gomod" :go.mod]
 [:BufEnter :startinsert :dap-repl]
 [:BufReadPost :JumpToLastLocation]
 [:BufWritePre "TrimTrailingSpace | TrimTrailingBlankLines" :*.txt]
 [:BufWritePre :AutoIndent :*.vim]]

