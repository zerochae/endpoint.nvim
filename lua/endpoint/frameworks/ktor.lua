local Framework = require "endpoint.core.Framework"
local class = require "endpoint.lib.middleclass"
local KtorParser = require "endpoint.parser.ktor_parser"

---@class endpoint.KtorFramework
local KtorFramework = class("KtorFramework", Framework)

---Creates a new KtorFramework instance
function KtorFramework:initialize()
  Framework.initialize(self, {
    name = "ktor",
    config = {
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
    },
  })
end

return KtorFramework
