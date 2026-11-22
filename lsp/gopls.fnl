(var mod-cache nil)
(var std-lib nil)

(fn identify-go-dir [custom-args]
  (let [cmd [:go :env custom-args.envvar_id]
        out (vim.fn.system cmd)
        trimmed (vim.trim (or out ""))]
    (if (and (not= trimmed "") (= 0 vim.v.shell_error))
        (if (and custom-args.custom_subdir (not= custom-args.custom_subdir ""))
            (.. trimmed custom-args.custom_subdir)
            trimmed)
        nil)))

;; fnlfmt: skip
(fn get-std-lib-dir []
  (if (and std-lib (not= std-lib ""))
      std-lib
      (do
        (set std-lib (identify-go-dir {:custom_subdir :/src :envvar_id :GOROOT}))
        std-lib)))

;; fnlfmt: skip
(fn get-mod-cache-dir []
  (if (and mod-cache (not= mod-cache ""))
      mod-cache
      (do
        (set mod-cache (identify-go-dir {:envvar_id :GOMODCACHE}))
        mod-cache)))

(fn get-root-dir [fname]
  (or (and mod-cache (= (fname:sub 1 (length mod-cache)) mod-cache)
           (let [clients (vim.lsp.get_clients {:name :gopls})]
             (if (> (length clients) 0)
                 (. clients (length clients) :config :root_dir))))
      (and std-lib (= (fname:sub 1 (length std-lib)) std-lib)
           (let [clients (vim.lsp.get_clients {:name :gopls})]
             (if (> (length clients) 0)
                 (. clients (length clients) :config :root_dir))))
      (vim.fs.root fname "go.work") (vim.fs.root fname "go.mod")
      (vim.fs.root fname ".git")))

{:cmd [:gopls]
 ;[:gopls :-remote=auto :-remote.listen.timeout=2h]
 :filetypes [:go :gomod :gowork :gotmpl :template]
 :root_dir (fn [bufnr on-dir]
             (let [fname (vim.api.nvim_buf_get_name bufnr)]
               (get-mod-cache-dir)
               (get-std-lib-dir)
               (on-dir (get-root-dir fname))))
 :single_file_support true
 :settings {:gopls {:vulncheck :Imports
                    ;; https://github.com/golang/tools/blob/master/gopls/doc/analyzers.md
                    :analyses {:appendclipped true
                               :fieldalignment true
                               :shadow true
                               :slicesdelete true
                               ; Merge conditional assignment into variable declaration
                               :QF1007 true
                               ; Omit redundant type from variable declaration
                               :QF1011 true
                               ; Omit comparison with boolean constant
                               :S1002 true
                               ; Drop unnecessary use of the blank identifier
                               :S1005 true
                               ; Use 'for { ... }' for infinite loops
                               :S1006 true
                               ; Simplify returning boolean expression
                               :S1008 true
                               ; Use a type conversion instead of manually copying struct fields
                               :S1016 true
                               ; Merge variable declaration and assignment
                               :S1021 true
                               ; Don't use fmt.Sprintf("%s", x) unnecessarily
                               :S1025 true
                               ; Range over the string directly
                               :S1029 true
                               ; Invalid regular expression
                               :SA1000 true
                               ; Invalid format in time.Parse
                               :SA1002 true
                               ; Unsupported argument to functions in encoding/binary
                               :SA1003 true
                               ; Invalid URL in net/url.Parse
                               :SA1007 true
                               ; (*regexp.Regexp).FindAll called with n == 0, which will always return zero results
                               :SA1010 true
                               ; Various methods in the 'strings' package expect valid UTF-8, but invalid input is provided
                               :SA1011 true
                               ; Non-pointer value passed to Unmarshal or Decode
                               :SA1014 true
                               ; Using time.Tick in a way that will leak. Consider using time.NewTicker, and only use time.Tick in tests, commands and endless functions
                               :SA1015 true
                               ; Channels used with os/signal.Notify should be buffered
                               :SA1017 true
                               ; strings.Replace called with n == 0, which does nothing
                               :SA1018 true
                               ; Using an invalid host:port pair with a net.Listen-related function
                               :SA1020 true
                               ; Using bytes.Equal to compare two net.IP
                               :SA1021 true
                               ; Modifying the buffer in an io.Writer implementation
                               :SA1023 true
                               ; A string cutset contains duplicate characters
                               :SA1024 true
                               ; It is not possible to use (*time.Timer).Reset's return value correctly
                               :SA1025 true
                               ; Cannot marshal channels or functions
                               :SA1026 true
                               ; Atomic access to 64-bit variable must be 64-bit aligned
                               :SA1027 true
                               ; sort.Slice can only be used on slices
                               :SA1028 true
                               ; Inappropriate key in call to context.WithValue
                               :SA1029 true
                               ; Invalid argument in call to a strconv function
                               :SA1030 true
                               ; Overlapping byte slices passed to an encoder
                               :SA1031 true
                               ; Wrong order of arguments to errors.Is
                               :SA1032 true
                               ; Called testing.T.FailNow or SkipNow in a goroutine, which isn't allowed
                               :SA2002 true
                               ; Deferred Lock right after locking, likely meant to defer Unlock instead
                               :SA2003 true
                               ; Field assignment that will never be observed. Did you mean to use a pointer receiver?
                               :SA4005 true
                               ; A value assigned to a variable is never read before being overwritten. Forgotten error check or dead code?
                               :SA4006 true
                               ; The variable in the loop condition never changes, are you incrementing the wrong variable?
                               :SA4008 true
                               ; A function argument is overwritten before its first use
                               :SA4009 true
                               ; The result of append will never be observed anywhere
                               :SA4010 true
                               ; Break statement with no effect. Did you mean to break out of an outer loop?
                               :SA4011 true
                               ; Comparing a value against NaN even though no value is equal to NaN
                               :SA4012 true
                               ; Calling functions like math.Ceil on floats converted from integers doesn't do anything useful
                               :SA4015 true
                               ; Discarding the return values of a function without side effects, making the call pointless
                               :SA4017 true
                               ; Self-assignment of variables
                               :SA4018 true
                               ; Impossible comparison of interface value with untyped nil
                               :SA4023 true
                               ; Checking never-nil value against nil
                               :SA4031 true
                               ; Assignment to nil map
                               :SA5000 true
                               ; The empty for loop ('for {}') spins and can block the scheduler
                               :SA5002 true
                               ; The finalizer references the finalized object, preventing garbage collection
                               :SA5005 true
                               ; Infinite recursive call
                               :SA5007 true
                               ; Impossible type assertion
                               :SA5010 true
                               ; Possible nil pointer dereference
                               :SA5011 true
                               ; Passing odd-sized slice to function expecting even size
                               :SA5012 true
                               ; Using regexp.Match or related in a loop, should use regexp.Compile
                               :SA6000 true
                               ; Missing an optimization opportunity when indexing maps by byte slices
                               :SA6001 true
                               ; Storing non-pointer values in sync.Pool allocates memory
                               :SA6002 true
                               ; Converting a string to a slice of runes before ranging over it
                               :SA6003 true
                               ; Defers in range loops may not run when you expect them to
                               :SA9001 true
                               ; Empty body in an if or else branch
                               :SA9003 true
                               ; Trying to marshal a struct with no public fields nor custom marshaling
                               :SA9005 true
                               ; Deleting a directory that shouldn't be deleted
                               :SA9007 true
                               ; else branch of a type assertion is probably not reading the right value
                               :SA9008 true
                               ; Incorrect or missing package comment
                               :ST1000 true
                               ; Dot imports are discouraged
                               :ST1001 true
                               ; Poorly chosen identifier
                               :ST1003 true
                               ; Incorrectly formatted error string
                               :ST1005 true
                               ; Poorly chosen receiver name
                               :ST1006 true
                               ; A function's error value should be its last return value
                               :ST1008 true
                               ; Poorly chosen name for variable of type time.Duration
                               :ST1011 true
                               ; Poorly chosen name for error variable
                               :ST1012 true
                               ; Should use constants for HTTP error codes, not magic numbers
                               :ST1013 true
                               ; A switch's default case should be the first or last case
                               :ST1015 true
                               ; Use consistent method receiver names
                               :ST1016 true
                               ; Don't use Yoda conditions
                               :ST1017 true
                               ; Avoid zero-width and control characters in string literals
                               :ST1018 true
                               ; Importing the same package multiple times
                               :ST1019 true
                               ; The documentation of an exported function should start with the function's name
                               :ST1020 true
                               ; The documentation of an exported type should start with type's name
                               :ST1021 true
                               ; The documentation of an exported variable or constant should start with variable's name
                               :ST1022 true
                               ; Redundant type in variable declaration
                               :ST1023 true}
                    :buildFlags [:-tags=test]
                    :directoryFilters [:-**/node_modules :-**/testdata]
                    :templateExtensions [:tmpl]
                    :codelenses {:test true :vulncheck true}
                    :staticcheck true
                    :gofumpt false
                    :hoverKind :FullDocumentation
                    ;; :SynopsisDocumentation
                    ; https://github.com/golang/tools/blob/master/gopls/doc/inlayHints.md
                    :hints {:assignVariableTypes true
                            :compositeLiteralFields true
                            :compositeLiteralTypes true
                            :constantValues true
                            :functionTypeParameters true
                            :ignoredError true
                            :parameterNames true
                            :rangeVariableTypes true}
                    :experimentalPostfixCompletions true
                    :renameMovesSubpackages true
                    :semanticTokens true
                    :usePlaceholders false
                    :local vim.env.GOPRIVATE}}}
