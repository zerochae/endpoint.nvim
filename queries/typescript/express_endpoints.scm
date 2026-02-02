; Express.js endpoint detection queries
; Find app.get, app.post, router.get, etc.
(call_expression
  function: (member_expression
    object: (identifier) @object.name
    property: (property_identifier) @method.name
    (#match? @object.name "^(app|router|Router)$")
    (#match? @method.name "^(get|post|put|delete|patch|all|options|head|use)$")
  )
  arguments: (arguments
    (string)? @route.path
    (template_string)? @route.template
  )
) @endpoint
