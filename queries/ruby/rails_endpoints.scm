; Rails endpoint detection queries
; Find route definitions in routes.rb

; HTTP method calls: get '/path', post '/path', etc.
(call
  method: (identifier) @method.name
  arguments: (argument_list
    (string (string_content) @route.path)?
    (simple_symbol) @route.symbol?
  )
  (#match? @method.name "^(get|post|put|patch|delete|match|root)$")
) @route

; resources and resource calls
(call
  method: (identifier) @resources.name
  arguments: (argument_list
    (simple_symbol) @resources.symbol
  )
  (#match? @resources.name "^(resources|resource)$")
) @resources
