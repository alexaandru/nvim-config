(fn LoadLocalCfg []
  (if (= 1 (vim.fn.filereadable :.nvimrc))
      (vim.cmd "so .nvimrc")))

; FIXME: kind of broken atm, works on and off...
(fn GitStatus []
  (let [git #(vim.fn.system (.. "git " $))
        branch (vim.trim (git "rev-parse --abbrev-ref HEAD 2> /dev/null"))]
    (if (not= branch "")
        (let [dirty (.. (git "diff --quiet || echo -n \\*")
                        (git "diff --cached --quiet || echo -n \\+"))]
          (set vim.w.git_status (.. branch dirty))))))

(fn ReColor []
  (let [name (.. :froggy.colors. vim.g.colors_name)]
    (tset package.loaded name nil)
    ((require :froggy) (require name)))
  (vim.cmd :redr!))

;; Format is: [<item>], where each <item> is itself a list of:
;; <event>,                // event type (string or list)
;; <command_or_callback>,  // command (string) or callback (function)
;; [, <buffer_or_pattern>  // buffer (number) or pattern (string), default is "*"
;;  [, <desc>]]            // callback description
[[[:VimEnter :DirChanged] LoadLocalCfg]
 [[:VimEnter :DirChanged :WinNew :WinEnter] GitStatus]
 [:TextYankPost #(vim.highlight.on_yank {:timeout 450})]
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
 [:BufEnter :startinsert :dap-repl]
 [:BufReadPost :JumpToLastLocation]
 [:BufWritePost ReColor :*froggy/*]
 [:BufWritePre "TrimTrailingSpace | TrimTrailingBlankLines" :*.txt]]

