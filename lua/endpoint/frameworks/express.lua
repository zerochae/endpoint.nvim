local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
local annotation_parser = require "endpoint.parser.annotation_parser"

---@class endpoint.ExpressFramework : endpoint.Framework
local ExpressFramework = setmetatable({}, { __index = Framework })
ExpressFramework.__index = ExpressFramework

---Creates a new ExpressFramework instance
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
function ExpressFramework:_initialize()
  -- Setup detector
  self.detector = dependency_detector:new(
    { "express", "Express" },
    { "package.json" },
    "express_dependency_detection"
  )

  -- Setup parser with Express route patterns
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

  self.parser = annotation_parser:new(
    express_annotation_patterns,
    express_path_extraction_patterns,
    express_method_mapping
  )
end

---Detects if Express is present in the current project
function ExpressFramework:detect()
  return self.detector:is_target_detected()
end

---Parses Express content to extract endpoint information
function ExpressFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parser:parse_content(content, file_path, line_number, column)

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
