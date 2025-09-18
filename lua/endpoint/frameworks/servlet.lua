local Framework = require "endpoint.core.Framework"
local Detector = require "endpoint.core.Detector"
local ServletParser = require "endpoint.parser.servlet_parser"

---@class endpoint.ServletFramework
local ServletFramework = setmetatable({}, { __index = Framework })
ServletFramework.__index = ServletFramework

---Creates a new ServletFramework instance
function ServletFramework:new()
  local servlet_framework_instance = Framework.new(self, "servlet", {
    file_extensions = { "*.java", "*.xml" },
    exclude_patterns = { "**/target", "**/build", "**/.gradle" },
    patterns = {
      GET = { "doGet", "@WebServlet" },
      POST = { "doPost", "@WebServlet" },
      PUT = { "doPut", "@WebServlet" },
      DELETE = { "doDelete", "@WebServlet" },
      PATCH = { "doPatch", "@WebServlet" },
    },
    search_options = { "--case-sensitive", "--type", "java" },
    controller_extractors = {
      { pattern = "([^/]+)%.java$" }
    },
  })
  setmetatable(servlet_framework_instance, self)
  return servlet_framework_instance
end

---Sets up detection and parsing for Servlet
function ServletFramework:_initialize()
  -- Setup detector
  self.detector = Detector:new_dependency_detector(
    { "servlet-api", "javax.servlet", "jakarta.servlet" },
    { "web.xml", "WEB-INF/web.xml", "src/main/webapp/WEB-INF/web.xml", "pom.xml", "build.gradle" },
    "servlet_dependency_detection"
  )

  -- Setup Servlet-specific parser
  self.parser = ServletParser:new()
end

return ServletFramework