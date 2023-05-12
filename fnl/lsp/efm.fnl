(fn fmt [formatCommand formatStdin]
  {: formatCommand :formatStdin (not= formatStdin false)})

(fn lint [lintCommand lintFormats lintStdin]
  (set-forcibly! lintFormats (or lintFormats ["%f:%l:%c: %m"]))
  {: lintCommand
   : lintFormats
   :lintStdin (not= lintStdin false)
   :lintIgnoreExitCode true})

;; NOTE: any linter severity must eventually map to one of the codes in :errorformat : E W I N
;; TODO: consider using https://github.com/fsouza/prettierd
(local prettier (fmt "prettier -w --no-semi --stdin-filepath ${INPUT}"))
(local eslint (vim.tbl_extend :keep
                              (fmt "eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}")
                              (lint "eslint_d -f visualstudio --stdin --stdin-filename ${INPUT}"
                                    ["%f(%l,%c): %trror %m"
                                     "%f(%l,%c): %tarn %m"])))

(local luacheck ;;
       (lint (.. "bash -c 'luacheck --globals vim --formatter plain -- ${INPUT}|"
                 "sed s\"/^/Warn /\"'") ["%tarn %f:%l:%c: %m"]))

(local actionLint (lint "actionlint --oneline ${INPUT}"))
(local rootMarkers [:go.mod :package.json :.git])
(local languages ;;
       {:lua [(fmt "lua-format -i") luacheck]
        :d2 [(fmt "d2 fmt -")]
        :fennel [(fmt "fnlfmt -" true)]
        :json [(fmt "jq .") (lint "jsonlint ${INPUT}")]
        :javascript [prettier eslint]
        :typescript [prettier eslint]
        :vue [prettier eslint]
        ; TODO: limit actionLint only to Github Actions, not all YAMLs!!
        :yaml [prettier actionLint]
        :html [prettier]
        :scss [prettier]
        :css [prettier]
        :markdown [prettier]})

{:cmd [:efm-langserver]
 :root_markers [:.git]
 :settings {: languages : rootMarkers :lintDebounce :150ms}
 :filetypes (vim.tbl_keys languages)
 :on_attach #(let [opts (. languages (vim.fn.getbufvar $2 :&ft))
                   sc $.server_capabilities]
               (set sc.documentFormattingProvider false)
               (each [_ v (ipairs opts)]
                 (if v.formatCommand (set sc.documentFormattingProvider true))))}
