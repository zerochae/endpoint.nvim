local Framework = require "endpoint.core.Framework"
local KtorParser = require "endpoint.parser.ktor_parser"

---@class endpoint.KtorFramework
local KtorFramework = setmetatable({}, { __index = Framework })
KtorFramework.__index = KtorFramework

---Creates a new KtorFramework instance
function KtorFramework:new()
  local ktor_framework_instance = Framework.new(self, "ktor", {
    file_extensions = { "*.kt" },
    exclude_patterns = { "**/build", "**/target", "**/.gradle" },
    patterns = {
      GET = { "get\\s*\\(", "get\\s*\\{", "get<.*>\\s*\\(" },
      POST = { "post\\s*\\(", "post\\s*\\{", "post<.*>\\s*\\(" },
      PUT = { "put\\s*\\(", "put\\s*\\{", "put<.*>\\s*\\(" },
      DELETE = { "delete\\s*\\(", "delete\\s*\\{", "delete<.*>\\s*\\(" },
      PATCH = { "patch\\s*\\(", "patch\\s*\\{", "patch<.*>\\s*\\(" },
    },
    search_options = { "--case-sensitive", "--type", "kotlin", "-U", "--multiline-dotall" },
    controller_extractors = {
      {
        pattern = "([^/]+)%.kt$",
        transform = function(name)
          return name:gsub("Routes$", ""):gsub("Routing$", "")
        end,
      },
    },
    detector = {
      dependencies = { "io.ktor:ktor", "ktor-server", "io.ktor.plugin" },
      manifest_files = { "build.gradle", "build.gradle.kts", "pom.xml" },
      name = "ktor_dependency_detection",
    },
    parser = KtorParser,
  })
  setmetatable(ktor_framework_instance, self)
  return ktor_framework_instance
end

return KtorFramework
