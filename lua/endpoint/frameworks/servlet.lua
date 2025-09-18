local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
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
  })
  setmetatable(servlet_framework_instance, self)
  return servlet_framework_instance
end

---Sets up detection and parsing for Servlet
function ServletFramework:_initialize()
  -- Setup detector
  self.detector = DependencyDetector:new(
    { "servlet-api", "javax.servlet", "jakarta.servlet" },
    { "web.xml", "WEB-INF/web.xml", "src/main/webapp/WEB-INF/web.xml", "pom.xml", "build.gradle" },
    "servlet_dependency_detection"
  )

  -- Setup Servlet-specific parser
  self.parser = ServletParser:new()
end

---Extract controller name from Servlet file path
function ServletFramework:getControllerName(file_path)
  -- Servlet: com/example/UserServlet.java → UserServlet
  local name = file_path:match "([^/]+)%.java$"
  if name then
    return name
  end
  return nil
end

return ServletFramework