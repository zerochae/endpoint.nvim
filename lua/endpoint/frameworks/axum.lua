local Framework = require "endpoint.core.Framework"
local Detector = require "endpoint.core.Detector"
local annotation_parser = require "endpoint.parser.annotation_parser"

---@class endpoint.AxumFramework : endpoint.Framework
local AxumFramework = setmetatable({}, { __index = Framework })
AxumFramework.__index = AxumFramework

---Creates a new AxumFramework instance
function AxumFramework:new()
  local axum_framework_instance = Framework.new(self, "axum", {
    file_extensions = { "*.rs" },
    exclude_patterns = { "**/target", "**/node_modules" },
    patterns = {
      GET = { "\\.get\\(", "Router::new\\(\\).*\\.route.*get" },
      POST = { "\\.post\\(", "Router::new\\(\\).*\\.route.*post" },
      PUT = { "\\.put\\(", "Router::new\\(\\).*\\.route.*put" },
      DELETE = { "\\.delete\\(", "Router::new\\(\\).*\\.route.*delete" },
      PATCH = { "\\.patch\\(", "Router::new\\(\\).*\\.route.*patch" },
    },
    search_options = { "--type", "rust" }
  })
  setmetatable(axum_framework_instance, self)
  ---@cast axum_framework_instance AxumFramework
  return axum_framework_instance
end

---Sets up detection and parsing strategies for Axum
function AxumFramework:_initialize()
  -- Setup detector
  self.detector = dependency_detector:new(
    { "axum", "axum =" },
    { "Cargo.toml" },
    "axum_dependency_detection"
  )

  -- Setup parser with Axum route patterns
  local axum_annotation_patterns = {
    GET = { "%.get%(", "Router::new%(%).*%.route.*get" },
    POST = { "%.post%(", "Router::new%(%).*%.route.*post" },
    PUT = { "%.put%(", "Router::new%(%).*%.route.*put" },
    DELETE = { "%.delete%(", "Router::new%(%).*%.route.*delete" },
    PATCH = { "%.patch%(", "Router::new%(%).*%.route.*patch" },
    OPTIONS = { "%.options%(", "Router::new%(%).*%.route.*options" },
    HEAD = { "%.head%(", "Router::new%(%).*%.route.*head" }
  }

  local axum_path_extraction_patterns = {
    'route%(["\']([^"\']+)["\']',    -- .route("/path", ...)
    '%("([^"]+)"[^,)]*[,)]',         -- .get("/path")
    "%('([^']+)'[^,)]*[,)]",         -- .get('/path')
  }

  local axum_method_mapping = {
    ["%.get%("] = "GET",
    ["Router::new%(%).*%.route.*get"] = "GET",
    ["%.post%("] = "POST",
    ["Router::new%(%).*%.route.*post"] = "POST",
    ["%.put%("] = "PUT",
    ["Router::new%(%).*%.route.*put"] = "PUT",
    ["%.delete%("] = "DELETE",
    ["Router::new%(%).*%.route.*delete"] = "DELETE",
    ["%.patch%("] = "PATCH",
    ["Router::new%(%).*%.route.*patch"] = "PATCH"
  }

  self.parser = annotation_parser:new(
    axum_annotation_patterns,
    axum_path_extraction_patterns,
    axum_method_mapping
  )
end

---Detects if Axum is present in the current project
function AxumFramework:detect()
  return self.detector:is_target_detected()
end

---Parses Axum content to extract endpoint information
function AxumFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parser:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- Enhance with Axum-specific metadata
    parsed_endpoint.tags = parsed_endpoint.tags or {}
    table.insert(parsed_endpoint.tags, "rust")
    table.insert(parsed_endpoint.tags, "axum")

    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "axum"
    parsed_endpoint.metadata.language = "rust"
  end

  return parsed_endpoint
end

return AxumFramework
