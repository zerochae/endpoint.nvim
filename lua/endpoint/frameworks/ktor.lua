local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
local annotation_parser = require "endpoint.parser.annotation_parser"

---@class endpoint.KtorFramework : endpoint.Framework
local KtorFramework = setmetatable({}, { __index = Framework })
KtorFramework.__index = KtorFramework

---Creates a new KtorFramework instance
function KtorFramework:new()
  local ktor_framework_instance = Framework.new(self, "ktor", {
    file_extensions = { "*.kt", "*.java" },
    exclude_patterns = { "**/build", "**/target", "**/.gradle" },
    patterns = {
      GET = { "get\\(", "routing.*get\\(" },
      POST = { "post\\(", "routing.*post\\(" },
      PUT = { "put\\(", "routing.*put\\(" },
      DELETE = { "delete\\(", "routing.*delete\\(" },
      PATCH = { "patch\\(", "routing.*patch\\(" },
    },
    search_options = { "--type", "kotlin" }
  })
  setmetatable(ktor_framework_instance, self)
  ---@cast ktor_framework_instance KtorFramework
  return ktor_framework_instance
end

---Sets up detection and parsing strategies for Ktor
function KtorFramework:_initialize()
  -- Setup detector
  self.detector = dependency_detector:new(
    { "io.ktor:ktor", "ktor-server" },
    { "build.gradle", "build.gradle.kts", "pom.xml" },
    "ktor_dependency_detection"
  )

  -- Setup parser with Ktor route patterns
  local ktor_annotation_patterns = {
    GET = { "get%(", "routing.*get%(" },
    POST = { "post%(", "routing.*post%(" },
    PUT = { "put%(", "routing.*put%(" },
    DELETE = { "delete%(", "routing.*delete%(" },
    PATCH = { "patch%(", "routing.*patch%(" },
    OPTIONS = { "options%(", "routing.*options%(" },
    HEAD = { "head%(", "routing.*head%(" }
  }

  local ktor_path_extraction_patterns = {
    '%("([^"]+)"[^)]*%)',     -- get("/path")
    "%('([^']+)'[^)]*%)",     -- get('/path')
  }

  local ktor_method_mapping = {
    ["get%("] = "GET",
    ["routing.*get%("] = "GET",
    ["post%("] = "POST",
    ["routing.*post%("] = "POST",
    ["put%("] = "PUT",
    ["routing.*put%("] = "PUT",
    ["delete%("] = "DELETE",
    ["routing.*delete%("] = "DELETE",
    ["patch%("] = "PATCH",
    ["routing.*patch%("] = "PATCH"
  }

  self.parser = annotation_parser:new(
    ktor_annotation_patterns,
    ktor_path_extraction_patterns,
    ktor_method_mapping
  )
end

---Detects if Ktor is present in the current project
function KtorFramework:detect()
  return self.detector:is_target_detected()
end

---Parses Ktor content to extract endpoint information
function KtorFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parser:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- Enhance with Ktor-specific metadata
    parsed_endpoint.tags = parsed_endpoint.tags or {}
    table.insert(parsed_endpoint.tags, "kotlin")
    table.insert(parsed_endpoint.tags, "ktor")

    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "ktor"
    parsed_endpoint.metadata.language = "kotlin"
  end

  return parsed_endpoint
end

return KtorFramework
