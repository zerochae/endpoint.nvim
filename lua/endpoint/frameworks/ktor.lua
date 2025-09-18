local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
local KtorParser = require "endpoint.parser.ktor_parser"

---@class endpoint.KtorFramework
local KtorFramework = setmetatable({}, { __index = Framework })
KtorFramework.__index = KtorFramework

---Creates a new KtorFramework instance
function KtorFramework:new()
  local ktor_framework_instance = Framework.new(self, "ktor", {
    file_extensions = { "*.kt", "*.java" },
    exclude_patterns = { "**/build", "**/target", "**/.gradle" },
    patterns = {
      GET = { "get\\(", "get<.*>\\(" },
      POST = { "post\\(", "post<.*>\\(" },
      PUT = { "put\\(", "put<.*>\\(" },
      DELETE = { "delete\\(", "delete<.*>\\(" },
      PATCH = { "patch\\(", "patch<.*>\\(" },
    },
    search_options = { "--case-sensitive", "--type", "kotlin" },
  })
  setmetatable(ktor_framework_instance, self)
  return ktor_framework_instance
end

---Sets up detection and parsing for Ktor
function KtorFramework:_initialize()
  -- Setup detector
  self.detector = DependencyDetector:new(
    { "io.ktor:ktor", "ktor-server", "io.ktor.plugin" },
    { "build.gradle", "build.gradle.kts", "pom.xml" },
    "ktor_dependency_detection"
  )

  -- Setup Ktor-specific parser
  self.parser = KtorParser:new()
end

---Extract controller name from Ktor file path
function KtorFramework:getControllerName(file_path)
  -- Ktor: src/main/kotlin/routes/UserRoutes.kt → UserRoutes
  local name = file_path:match "([^/]+)%.kt$"
  if name then
    return name:gsub("Routes$", ""):gsub("Routing$", "")
  end
  return nil
end

return KtorFramework
