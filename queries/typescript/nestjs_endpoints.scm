; NestJS endpoint detection queries
; Find @Get, @Post, @Put, @Delete, @Patch decorators
(decorator
  (call_expression
    function: (identifier) @decorator.name
    arguments: (arguments
      (string)? @decorator.path
    )?
    (#match? @decorator.name "^(Get|Post|Put|Delete|Patch|All|Options|Head)$")
  )
) @decorator

; Find @Controller decorator for base path
(decorator
  (call_expression
    function: (identifier) @controller.name
    arguments: (arguments
      (string)? @controller.path
    )?
    (#eq? @controller.name "Controller")
  )
) @controller.decorator
