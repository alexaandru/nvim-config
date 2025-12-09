; extends

; Inject Lua patterns in :gsub calls
; Matches: (: :gsub "pattern" "replacement")
; Also matches: (: str :gsub "pattern" "replacement")
(list
  call: (symbol) @_method
  (#eq? @_method ":")
  (string
    content: (string_content) @_method_name)
  (#eq? @_method_name "gsub")
  (string
    content: (string_content) @injection.content
    (#set! injection.language "luap")
    (#set! priority 101)))
