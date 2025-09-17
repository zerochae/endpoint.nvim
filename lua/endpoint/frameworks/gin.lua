local Framework = require "endpoint.core.Framework"
local DependencyDetectionStrategy = require "endpoint.core.strategies.detection.DependencyDetectionStrategy"
local AnnotationParsingStrategy = require "endpoint.core.strategies.parsing.AnnotationParsingStrategy"

---@class GinFramework : Framework
local GinFramework = setmetatable({}, { __index = Framework })
GinFramework.__index = GinFramework

---Creates a new GinFramework instance
---@return GinFramework
function GinFramework:new()
  local gin_framework_instance = Framework.new(self, "gin", {
    file_extensions = { "*.go" },
    exclude_patterns = { "**/vendor", "**/node_modules" },
    patterns = {
      GET = { "r\\.GET\\(", "router\\.GET\\(" },
      POST = { "r\\.POST\\(", "router\\.POST\\(" },
      PUT = { "r\\.PUT\\(", "router\\.PUT\\(" },
      DELETE = { "r\\.DELETE\\(", "router\\.DELETE\\(" },
      PATCH = { "r\\.PATCH\\(", "router\\.PATCH\\(" },
    },
    search_options = { "--type", "go" }
  })
  setmetatable(gin_framework_instance, self)
  ---@cast gin_framework_instance GinFramework
  return gin_framework_instance
end

---Sets up detection and parsing strategies for Gin
---@protected
function GinFramework:_setup_strategies()
  -- Setup detection strategy
  self.detection_strategy = DependencyDetectionStrategy:new(
    { "gin-gonic/gin", "github.com/gin-gonic/gin" },
    { "go.mod", "go.sum" },
    "gin_dependency_detection"
  )

  -- Setup parsing strategy with Gin route patterns
  local gin_annotation_patterns = {
    GET = { "r%.GET%(", "router%.GET%(" },
    POST = { "r%.POST%(", "router%.POST%(" },
    PUT = { "r%.PUT%(", "router%.PUT%(" },
    DELETE = { "r%.DELETE%(", "router%.DELETE%(" },
    PATCH = { "r%.PATCH%(", "router%.PATCH%(" },
    OPTIONS = { "r%.OPTIONS%(", "router%.OPTIONS%(" },
    HEAD = { "r%.HEAD%(", "router%.HEAD%(" }
  }

  local gin_path_extraction_patterns = {
    '%("([^"]+)"[^,)]*[,)]',   -- r.GET("/path", ...)
    "%('([^']+)'[^,)]*[,)]",   -- r.GET('/path', ...)
    '%(`([^`]+)`[^,)]*[,)]',   -- r.GET(`/path`, ...)
  }

  local gin_method_mapping = {
    ["r%.GET%("] = "GET",
    ["router%.GET%("] = "GET",
    ["r%.POST%("] = "POST",
    ["router%.POST%("] = "POST",
    ["r%.PUT%("] = "PUT",
    ["router%.PUT%("] = "PUT",
    ["r%.DELETE%("] = "DELETE",
    ["router%.DELETE%("] = "DELETE",
    ["r%.PATCH%("] = "PATCH",
    ["router%.PATCH%("] = "PATCH"
  }

  self.parsing_strategy = AnnotationParsingStrategy:new(
    gin_annotation_patterns,
    gin_path_extraction_patterns,
    gin_method_mapping
  )
end

---Detects if Gin is present in the current project
---@return boolean
function GinFramework:detect()
  return self.detection_strategy:is_target_detected()
end

---Parses Gin content to extract endpoint information
---@param content string The content to parse
---@param file_path string Path to the file
---@param line_number number Line number in the file
---@param column number Column number in the line
---@return endpoint.entry|nil
function GinFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parsing_strategy:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- Enhance with Gin-specific metadata
    parsed_endpoint.tags = parsed_endpoint.tags or {}
    table.insert(parsed_endpoint.tags, "go")
    table.insert(parsed_endpoint.tags, "gin")

    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "gin"
    parsed_endpoint.metadata.language = "go"
  end

  return parsed_endpoint
end

return GinFramework