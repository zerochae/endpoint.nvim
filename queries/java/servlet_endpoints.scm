; Java Servlet endpoint detection queries
; Find @WebServlet annotation with urlPatterns
(class_declaration
  (modifiers
    (annotation
      name: (identifier) @annotation.name
      arguments: (annotation_argument_list)? @annotation.args
      (#eq? @annotation.name "WebServlet")
    ) @annotation
  )
  name: (identifier) @class.name
) @class

; Find doXxx method declarations (doGet, doPost, etc.)
(method_declaration
  (modifiers)? @modifiers
  type: (void_type)
  name: (identifier) @method.name
  (#match? @method.name "^do(Get|Post|Put|Delete|Patch|Options|Head)$")
) @method
