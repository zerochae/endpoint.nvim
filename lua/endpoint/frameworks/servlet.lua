local Framework = require "endpoint.core.Framework"
local class = require "endpoint.lib.middleclass"
local ServletParser = require "endpoint.parser.servlet_parser"

---@class endpoint.ServletFramework
local ServletFramework = class("ServletFramework", Framework)

---Creates a new ServletFramework instance
function ServletFramework:initialize()
  Framework.initialize(self, {
    name = "servlet",
    config = {
      file_extensions = { "*.java", "*.xml" },
      exclude_patterns = { "**/target", "**/build", "**/.gradle" },
      patterns = {
        GET = { "doGet" },
        POST = { "doPost" },
        PUT = { "doPut" },
        DELETE = { "doDelete" },
        PATCH = { "doPatch" },
      },
      search_options = { "--case-sensitive", "--type", "java", "-U", "--multiline-dotall" },
      controller_extractors = {
        { pattern = "([^/]+)%.java$" },
      },
      detector = {
        dependencies = { "servlet-api", "javax.servlet", "jakarta.servlet" },
        manifest_files = { "web.xml", "WEB-INF/web.xml", "src/main/webapp/WEB-INF/web.xml", "pom.xml", "build.gradle" },
        name = "servlet_dependency_detection",
        additional_checks = {
          has_webapp_structure = { "WEB-INF/", "src/main/webapp/" },
          has_servlet_annotations = "@WebServlet",
        },
      },
      parser = ServletParser,
    },
  })
end

return ServletFramework
