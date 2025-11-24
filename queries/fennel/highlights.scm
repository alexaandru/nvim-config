; inherits: fennel

; Highlight pack source strings in package definitions
(table
  (table_pair
    key: (string
      (string_content) @_field_name)
    (#eq? @_field_name "src")
    value: (string) @string.special.pack_name))

; Highlight standalone strings in sequences that contain tables with :src
(sequence
  (table
    (table_pair
      key: (string
        (string_content) @_src)
      (#eq? @_src "src"))) @_has_src
  (string) @string.special.pack_name)
