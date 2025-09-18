local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
local annotation_parser = require "endpoint.parser.annotation_parser"

---@class endpoint.NestJsFramework : endpoint.Framework
local NestJsFramework = setmetatable({}, { __index = Framework })
NestJsFramework.__index = NestJsFramework

---Creates a new NestJsFramework instance
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
  ---@cast nestjs_framework_instance NestJsFramework
  return nestjs_framework_instance
end

---Sets up detection and parsing strategies for NestJS
function NestJsFramework:_initialize()
  -- Setup detector
  self.detector = dependency_detector:new(
    { "@nestjs/core", "@nestjs/common", "nestjs" },
    { "package.json" },
    "nestjs_dependency_detection"
  )

  -- Setup parser with NestJS decorator patterns
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

  self.parser = annotation_parser:new(
    nestjs_annotation_patterns,
    nestjs_path_extraction_patterns,
    nestjs_method_mapping
  )
end

---Detects if NestJS is present in the current project
function NestJsFramework:detect()
  return self.detector:is_target_detected()
end

---Parses NestJS content to extract endpoint information
function NestJsFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parser:parse_content(content, file_path, line_number, column)

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
