; .NET endpoint detection queries
; Find [HttpGet], [HttpPost], [Route] attributes

(attribute
  name: (identifier) @attribute.name
  (attribute_argument_list
    (attribute_argument
      (string_literal) @attribute.path
    )?
  )?
  (#match? @attribute.name "^(HttpGet|HttpPost|HttpPut|HttpDelete|HttpPatch|Route)$")
) @attribute

; Controller-level Route attribute
(class_declaration
  (attribute_list
    (attribute
      name: (identifier) @controller.route.name
      (attribute_argument_list
        (attribute_argument
          (string_literal) @controller.route.path
        )
      )?
      (#eq? @controller.route.name "Route")
    )
  )
  name: (identifier) @controller.name
) @controller
