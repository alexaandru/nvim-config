(fn fmt [cmd stdin]
  {:formatCommand cmd :formatStdin (not= stdin false)})

(fn lint [cmd fmts stdin]
  (set-forcibly! fmts (or fmts ["%f:%l:%c: %m"]))
  {:lintCommand cmd
   :lintStdin (not= stdin false)
   :lintFormats fmts
   :lintIgnoreExitCode true})

;; TODO: use lintCategoryMap, see https://github.com/mattn/efm-langserver/issues/153,
;; wherever applicable. Also see :errorformat

;; consider using https://github.com/fsouza/prettierd
(local prettier (fmt "prettier -w --stdin-filepath ${INPUT}"))

(local eslint (vim.tbl_extend :keep
                              (fmt "eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}")
                              (lint "eslint_d -f visualstudio --stdin --stdin-filename ${INPUT}"
                                    ["%f(%l,%c): %trror %m"
                                     "%f(%l,%c): %tarning %m"])))

(local golangci (lint (.. "bash -c 'golangci-lint run --out-format github-actions|"
                          "grep =$(realpath --relative-to . ${INPUT})'")
                      ["::%trror file=%f,line=%l,col=%c::%m"
                       "::%tarn file=%f,line=%l,col=%c::%m"
                       "::%tnfo file=%f,line=%l,col=%c::%m"
                       "::%tint file=%f,line=%l,col=%c::%m"]
                      false))

(local fennelCmd
       (.. "bash -c 'export out=$(fennel --globals vim,jit,unpack,au,DisableProviders,DisableBuiltin,packadd ${INPUT} 2>&1); "
           "[[ \"$out\" =~ ^([a-zA-Z\\s\\d]*).error.in.(.*):([0-9]+) ]] && "
           "(echo -n \"Error ${BASH_REMATCH[2]}:${BASH_REMATCH[3]} ${BASH_REMATCH[1]} error: \"; "
           "echo \"$out\"|head -n2|tail -n1|cut -b3-)'"))

(local fennel (lint fennelCmd ["%trror %f:%l %m"] false))

(local luacheck (lint (.. "bash -c 'luacheck --globals vim --formatter plain -- ${INPUT}|"
                          "sed s\"/^/Warn /\"'")
                      ["%tarn %f:%l:%c: %m"]))

(local tfsec (lint (.. "bash -c 'tfsec --tfvars-file terraform.tfvars -fcsv|"
                       "sed \"s/,CRITICAL,/,ERROR,/i; s/,HIGH,/,ERROR,/i; s/,MEDIUM,/,WARN,/i; s/,LOW,/,NOTICE,/i\"|"
                       "cut -f1,2,3,5,6 -d,|grep ${INPUT}'")
                   ["%f,%l,%c,%tARN,%m"
                    "%f,%l,%c,%tRROR,%m"
                    "%f,%l,%c,%tOTICE,%m"]))

(local terrascan
       (lint (.. "bash -c 'terrascan scan -o json|"
                 "jq -r \".results.violations[]|[.file,.line,.severity,.description]|join(\\\",\\\")\"|"
                 "sed \"s#^deployment/##; s/,CRITICAL,/,ERROR,/i; s/,HIGH,/,ERROR,/i; s/,MEDIUM,/,WARN,/i; s/,LOW,/,NOTICE,/i\"|"
                 "grep $(realpath --relative-to . ${INPUT})'")
             ["%f,%l,%tARN,%m" "%f,%l,%tRROR,%m" "%f,%l,%tOTICE,%m"]))

(local credo {:lintCommand "mix credo suggest --format=flycheck --read-from-stdin ${INPUT}"
              :lintStdin true
              :lintFormats ["%f:%l:%c: %t: %m" "%f:%l: %t: %m"]
              :lintCategoryMap {:R :N :D :I :F :E :W :W}
              :rootMarkers [:mix.exs :mix.lock]})

(local cfg {:go [golangci]
            ;:hcl [tfsec terrascan] ;; FIXME: stability issues...
            :lua [(fmt "lua-format -i") luacheck]
            :fennel [(fmt "fnlfmt /dev/stdin" true) fennel]
            :elixir [credo]
            :erlang [(fmt "rebar3 fmt -")]
            :json [(fmt "jq .") (lint "jsonlint ${INPUT}")]
            :javascript [prettier eslint]
            :typescript [prettier eslint]
            :javascriptreact [prettier eslint]
            :typescriptreact [prettier eslint]
            :vue [prettier eslint]
            :yaml [prettier]
            :html [prettier]
            :scss [prettier]
            :css [prettier]
            :markdown [prettier]})

{:settings {:rootMarkers [:go.mod :package.json :.git] :languages cfg}
 :init_options {:documentFormatting false}
 :filetypes (vim.tbl_keys cfg)
 :on_attach (fn [client bufnr]
              (let [opts (. cfg (vim.fn.getbufvar bufnr :&ft))]
                (set client.resolved_capabilities.document_formatting false)
                (each [_ v (ipairs opts)]
                  (if v.formatCommand
                      (set client.resolved_capabilities.document_formatting
                           true))))
              ((. (require :lsp) :on_attach) client bufnr))}

