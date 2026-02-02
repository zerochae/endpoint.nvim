; Spring Boot endpoint detection queries
; Find method-level mapping annotations (@GetMapping, @PostMapping, etc.)

(method_declaration
  (modifiers
    (annotation
      name: (identifier) @annotation.name
      arguments: (annotation_argument_list
        ; Direct path: @GetMapping("/users")
        (string_literal)? @annotation.path.direct
        ; Named path: @GetMapping(value = "/users")
        (element_value_pair
          key: (identifier) @annotation.key
          value: (string_literal) @annotation.path.named
          (#any-of? @annotation.key "value" "path")
        )?
        ; Method parameter: @RequestMapping(method = RequestMethod.GET)
        (element_value_pair
          key: (identifier) @annotation.method.key
          value: (_) @annotation.method.value
          (#eq? @annotation.method.key "method")
        )?
      )? @annotation.args
    ) @annotation
    (#match? @annotation.name "^(Get|Post|Put|Delete|Patch|Request)Mapping$")
  ) @modifiers
  name: (identifier) @method.name
) @method

; Class-level @RequestMapping for base path
(class_declaration
  (modifiers
    (annotation
      name: (identifier) @class.annotation.name
      arguments: (annotation_argument_list
        (string_literal)? @class.path.direct
        (element_value_pair
          key: (identifier) @class.path.key
          value: (string_literal) @class.path.value
          (#any-of? @class.path.key "value" "path")
        )?
      )? @class.annotation.args
      (#eq? @class.annotation.name "RequestMapping")
    )
  )
  name: (identifier) @class.name
) @class
