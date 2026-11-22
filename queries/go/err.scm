(
  if_statement
    initializer: (short_var_declaration
      left: (expression_list (identifier) @err)
      right: (expression_list (_) @call))
    condition: (binary_expression
      left: (identifier) @err2
      right: (identifier) @nil)
    consequence: (block
      (return_statement
        (expression_list (identifier) @err3)))
) @if
