; FastAPI endpoint detection queries
; Find @app.get, @router.get decorators
(decorated_definition
  (decorator
    (call
      function: (attribute
        object: (identifier) @object.name
        attribute: (identifier) @method.name
        (#match? @object.name "^(app|router)$")
        (#match? @method.name "^(get|post|put|delete|patch|options|head)$")
      )
      arguments: (argument_list
        (string)? @route.path
      )
    )
  ) @decorator
  definition: (function_definition
    name: (identifier) @function.name
  )
) @endpoint
