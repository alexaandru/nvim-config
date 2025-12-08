; extends

((comment) @injection.content
  (#match? @injection.content "^// MAGIC [a-zA-Z\\s\\t]")
  ; (#set! injection.language "python")
  ; (#set! injection.combined)
  (#magic_set_lang! @injection.content)
  (#offset! @injection.content 0 9 0 1))
