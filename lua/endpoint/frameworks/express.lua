local Framework = require "endpoint.core.Framework"
local DependencyDetectionStrategy = require "endpoint.core.strategies.detection.DependencyDetectionStrategy"
local AnnotationParsingStrategy = require "endpoint.core.strategies.parsing.AnnotationParsingStrategy"

---@class ExpressFramework : Framework
local ExpressFramework = setmetatable({}, { __index = Framework })
ExpressFramework.__index = ExpressFramework

---Creates a new ExpressFramework instance
---@return ExpressFramework
function ExpressFramework:new()
  local express_framework_instance = Framework.new(self, "express", {
    file_extensions = { "*.js", "*.ts", "*.mjs" },
    exclude_patterns = { "**/node_modules", "**/dist", "**/build" },
    patterns = {
      GET = { "app\\.get\\(", "router\\.get\\(", "\\.get\\(" },
      POST = { "app\\.post\\(", "router\\.post\\(", "\\.post\\(" },
      PUT = { "app\\.put\\(", "router\\.put\\(", "\\.put\\(" },
      DELETE = { "app\\.delete\\(", "router\\.delete\\(", "\\.delete\\(" },
      PATCH = { "app\\.patch\\(", "router\\.patch\\(", "\\.patch\\(" },
    },
    search_options = { "--type", "js" }
  })
  setmetatable(express_framework_instance, self)
  ---@cast express_framework_instance ExpressFramework
  return express_framework_instance
end

---Sets up detection and parsing strategies for Express
---@protected
function ExpressFramework:_setup_strategies()
  -- Setup detection strategy
  self.detection_strategy = DependencyDetectionStrategy:new(
    { "express", "Express" },
    { "package.json" },
    "express_dependency_detection"
  )

  -- Setup parsing strategy with Express route patterns
  local express_annotation_patterns = {
    GET = { "app%.get%(", "router%.get%(", "%.get%(" },
    POST = { "app%.post%(", "router%.post%(", "%.post%(" },
    PUT = { "app%.put%(", "router%.put%(", "%.put%(" },
    DELETE = { "app%.delete%(", "router%.delete%(", "%.delete%(" },
    PATCH = { "app%.patch%(", "router%.patch%(", "%.patch%(" },
    OPTIONS = { "app%.options%(", "router%.options%(", "%.options%(" },
    HEAD = { "app%.head%(", "router%.head%(", "%.head%(" }
  }

  local express_path_extraction_patterns = {
    '%("([^"]+)"[^,)]*[,)]',   -- app.get("/path", ...)
    "%('([^']+)'[^,)]*[,)]",   -- app.get('/path', ...)
    '%(`([^`]+)`[^,)]*[,)]',   -- app.get(`/path`, ...)
  }

  local express_method_mapping = {
    ["app%.get%("] = "GET",
    ["router%.get%("] = "GET",
    ["%.get%("] = "GET",
    ["app%.post%("] = "POST",
    ["router%.post%("] = "POST",
    ["%.post%("] = "POST",
    ["app%.put%("] = "PUT",
    ["router%.put%("] = "PUT",
    ["%.put%("] = "PUT",
    ["app%.delete%("] = "DELETE",
    ["router%.delete%("] = "DELETE",
    ["%.delete%("] = "DELETE"
  }

  self.parsing_strategy = AnnotationParsingStrategy:new(
    express_annotation_patterns,
    express_path_extraction_patterns,
    express_method_mapping
  )
end

---Detects if Express is present in the current project
---@return boolean
function ExpressFramework:detect()
  return self.detection_strategy:is_target_detected()
end

---Parses Express content to extract endpoint information
---@param content string The content to parse
---@param file_path string Path to the file
---@param line_number number Line number in the file
---@param column number Column number in the line
---@return endpoint.entry|nil
function ExpressFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parsing_strategy:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- Enhance with Express-specific metadata
    parsed_endpoint.tags = parsed_endpoint.tags or {}
    table.insert(parsed_endpoint.tags, "javascript")
    table.insert(parsed_endpoint.tags, "express")

    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "express"
    parsed_endpoint.metadata.language = "javascript"
  end

  return parsed_endpoint
end

return ExpressFramework