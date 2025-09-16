-- Ktor Framework Module
local framework = require "endpoint.framework"

---@type endpoint.framework_base
return framework:new("ktor"):setup {
  file_extensions = { "*.kt", "*.kts" },
  exclude_patterns = { "**/build/**", "**/.gradle/**" },
  detection = {
    files = { "build.gradle.kts", "build.gradle", "src/main/kotlin" },
    dependencies = { "ktor-server", "io.ktor" },
    manifest_files = { "build.gradle", "build.gradle.kts" },
  },
  type = "pattern",
  patterns = {
    GET = { "get\\(" },
    POST = { "post\\(" },
    PUT = { "put\\(" },
    DELETE = { "delete\\(" },
    PATCH = { "patch\\(" },
  },
  parser = require "endpoint.frameworks.ktor.parser",
}