; Ktor endpoint detection queries
; Find route definitions: get("/path"), post("/path"), etc.

(call_expression
  (navigation_expression
    (simple_identifier) @object
    (navigation_suffix
      (simple_identifier) @method.name
      (#match? @method.name "^(get|post|put|delete|patch|head|options)$")
    )
  )
  (call_suffix
    (value_arguments
      (value_argument
        (string_literal) @route.path
      )?
    )
  )
) @route

; Direct function call style
(call_expression
  (simple_identifier) @method.name
  (#match? @method.name "^(get|post|put|delete|patch|head|options|route)$")
  (call_suffix
    (value_arguments
      (value_argument
        (string_literal) @route.path
      )?
    )
  )
) @route.direct
