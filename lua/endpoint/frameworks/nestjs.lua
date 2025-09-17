local Framework = require "endpoint.core.Framework"
local DependencyDetectionStrategy = require "endpoint.core.strategies.detection.DependencyDetectionStrategy"
local AnnotationParsingStrategy = require "endpoint.core.strategies.parsing.AnnotationParsingStrategy"

---@class NestJsFramework : Framework
local NestJsFramework = setmetatable({}, { __index = Framework })
NestJsFramework.__index = NestJsFramework

---Creates a new NestJsFramework instance
---@return NestJsFramework
function NestJsFramework:new()
  local nestjs_framework_instance = Framework.new(self, "nestjs", {
    file_extensions = { "*.ts", "*.js" },
    exclude_patterns = { "**/node_modules", "**/dist", "**/build" },
    patterns = {
      GET = { "@Get\\(", "@Controller\\(" },
      POST = { "@Post\\(", "@Controller\\(" },
      PUT = { "@Put\\(", "@Controller\\(" },
      DELETE = { "@Delete\\(", "@Controller\\(" },
      PATCH = { "@Patch\\(", "@Controller\\(" },
    },
    search_options = { "--type", "ts" }
  })
  setmetatable(nestjs_framework_instance, self)
  return nestjs_framework_instance
end

---Sets up detection and parsing strategies for NestJS
---@protected
function NestJsFramework:_setup_strategies()
  -- Setup detection strategy
  self.detection_strategy = DependencyDetectionStrategy:new(
    { "@nestjs/core", "@nestjs/common", "nestjs" },
    { "package.json" },
    "nestjs_dependency_detection"
  )

  -- Setup parsing strategy with NestJS decorator patterns
  local nestjs_annotation_patterns = {
    GET = { "@Get%(", "@Controller%(" },
    POST = { "@Post%(", "@Controller%(" },
    PUT = { "@Put%(", "@Controller%(" },
    DELETE = { "@Delete%(", "@Controller%(" },
    PATCH = { "@Patch%(", "@Controller%(" },
    OPTIONS = { "@Options%(", "@Controller%(" },
    HEAD = { "@Head%(", "@Controller%(" }
  }

  local nestjs_path_extraction_patterns = {
    '%("([^"]+)"[^)]*%)',   -- @Get("/path")
    "%('([^']+)'[^)]*%)",   -- @Get('/path')
    '%(`([^`]+)`[^)]*%)',   -- @Get(`/path`)
  }

  local nestjs_method_mapping = {
    ["@Get%("] = "GET",
    ["@Post%("] = "POST",
    ["@Put%("] = "PUT",
    ["@Delete%("] = "DELETE",
    ["@Patch%("] = "PATCH",
    ["@Options%("] = "OPTIONS",
    ["@Head%("] = "HEAD",
    ["@Controller%("] = "GET" -- Default for controller base path
  }

  self.parsing_strategy = AnnotationParsingStrategy:new(
    nestjs_annotation_patterns,
    nestjs_path_extraction_patterns,
    nestjs_method_mapping
  )
end

---Detects if NestJS is present in the current project
---@return boolean
function NestJsFramework:detect()
  return self.detection_strategy:is_target_detected()
end

---Parses NestJS content to extract endpoint information
---@param content string The content to parse
---@param file_path string Path to the file
---@param line_number number Line number in the file
---@param column number Column number in the line
---@return endpoint.entry|nil
function NestJsFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parsing_strategy:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- NestJS-specific controller base path handling
    if content:match("@Controller%(") then
      parsed_endpoint.metadata = parsed_endpoint.metadata or {}
      parsed_endpoint.metadata.controller_base_path = parsed_endpoint.endpoint_path
      parsed_endpoint.metadata.decorator_type = "controller"
    end

    -- Enhance with NestJS-specific metadata
    parsed_endpoint.tags = parsed_endpoint.tags or {}
    table.insert(parsed_endpoint.tags, "typescript")
    table.insert(parsed_endpoint.tags, "nestjs")

    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "nestjs"
    parsed_endpoint.metadata.language = "typescript"
  end

  return parsed_endpoint
end

return NestJsFramework