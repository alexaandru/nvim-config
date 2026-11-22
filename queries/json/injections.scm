; extends

; Inject CEL into "expr" values in greenlit rules.json
(pair
  key: (string (string_content) @_key)
  value: (string (string_content) @injection.content)
  (#eq? @_key "expr")
  (#set! injection.language "cel"))
