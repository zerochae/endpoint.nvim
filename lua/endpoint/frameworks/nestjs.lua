local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
local NestJsParser = require "endpoint.parser.nestjs_parser"

---@class endpoint.NestJsFramework
local NestJsFramework = setmetatable({}, { __index = Framework })
NestJsFramework.__index = NestJsFramework

---Creates a new NestJsFramework instance
function NestJsFramework:new()
  local nestjs_framework_instance = Framework.new(self, "nestjs", {
    file_extensions = { "*.ts", "*.js" },
    exclude_patterns = { "**/node_modules", "**/dist", "**/build" },
    patterns = {
      GET = { "@Get\\(", "@HttpCode.-@Get" },
      POST = { "@Post\\(", "@HttpCode.-@Post" },
      PUT = { "@Put\\(", "@HttpCode.-@Put" },
      DELETE = { "@Delete\\(", "@HttpCode.-@Delete" },
      PATCH = { "@Patch\\(", "@HttpCode.-@Patch" },
    },
    search_options = { "--case-sensitive", "--type", "ts" },
  })
  setmetatable(nestjs_framework_instance, self)
  return nestjs_framework_instance
end

---Sets up detection and parsing for NestJS
function NestJsFramework:_initialize()
  -- Setup detector
  self.detector = DependencyDetector:new(
    { "@nestjs/core", "@nestjs/common", "nestjs" },
    { "package.json", "tsconfig.json", "nest-cli.json" },
    "nestjs_dependency_detection"
  )

  -- Setup NestJS-specific parser
  self.parser = NestJsParser:new()
end

---Detects if NestJS is present in the current project
function NestJsFramework:detect()
  if not self.detector then
    self:_initialize()
  end
  if self.detector then
    return self.detector:is_target_detected()
  end
  return false
end

---Extract controller name from NestJS file path
function NestJsFramework:getControllerName(file_path)
  -- NestJS: src/users/users.controller.ts → UsersController
  local name = file_path:match "([^/]+)%.controller%.%w+$"
  if name then
    -- Convert kebab-case to PascalCase and add Controller suffix
    local pascal_name = name:gsub("%-(%w)", function(letter) return letter:upper() end)
    pascal_name = pascal_name:gsub("^%w", string.upper)
    return pascal_name .. "Controller"
  end

  -- Fallback: any .ts/.js file
  name = file_path:match "([^/]+)%.%w+$"
  if name then
    return name:gsub("Controller$", ""):gsub("Service$", "")
  end

  return nil
end

return NestJsFramework
