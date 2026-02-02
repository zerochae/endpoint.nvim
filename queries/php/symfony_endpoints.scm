; Symfony endpoint detection queries
; Find #[Route] attributes

(attribute
  (attribute_group
    (attribute
      name: (name) @attribute.name
      arguments: (arguments
        (argument
          (string (string_value) @route.path)?
        )
      )?
      (#match? @attribute.name "^(Route|Get|Post|Put|Delete|Patch)$")
    )
  )
) @attribute
