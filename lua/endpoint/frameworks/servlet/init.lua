-- Java Servlet Framework Module
local framework = require "endpoint.framework"

---@type endpoint.framework_base
return framework:new("servlet"):setup {
  file_extensions = { "*.java", "*.xml" },
  exclude_patterns = { "**/target/**", "**/build/**", "**/.gradle/**" },
  detection = {
    files = { "web.xml", "WEB-INF/web.xml", "src/main/webapp/" },
    dependencies = { "servlet-api", "javax.servlet", "jakarta.servlet" },
    manifest_files = { "pom.xml", "build.gradle" },
  },
  type = "pattern",
  patterns = {
    GET = { "doGet" },
    POST = { "doPost" },
    PUT = { "doPut" },
    DELETE = { "doDelete" },
    PATCH = { "doPatch" },
  },
  parser = require "endpoint.frameworks.servlet.parser",
}