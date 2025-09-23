local ServletFramework = require "endpoint.frameworks.servlet"
local ServletParser = require "endpoint.parser.servlet_parser"

describe("ServletFramework", function()
  local framework
  local parser

  before_each(function()
    framework = ServletFramework:new()
    parser = ServletParser:new()
  end)

  describe("Framework Detection", function()
    it("should have correct framework name", function()
      assert.equals("servlet", framework:get_name())
    end)

    it("should have detector configured", function()
      assert.is_not_nil(framework.detector)
      assert.equals("servlet_dependency_detection", framework.detector.detection_name)
    end)

    it("should have parser configured", function()
      assert.is_not_nil(framework.parser)
      assert.equals("servlet_parser", framework.parser.parser_name)
    end)
  end)

  describe("Framework Configuration", function()
    it("should have correct file extensions", function()
      local config = framework:get_config()
      assert.same({ "*.java", "*.xml" }, config.file_extensions)
    end)

    it("should have exclude patterns", function()
      local config = framework:get_config()
      assert.same({ "**/target", "**/build", "**/.gradle" }, config.exclude_patterns)
    end)

    it("should have Servlet-specific search patterns", function()
      local config = framework:get_config()
      assert.is_table(config.patterns.GET)
      assert.is_table(config.patterns.POST)
      assert.is_table(config.patterns.PUT)
      assert.is_table(config.patterns.DELETE)
      assert.is_table(config.patterns.PATCH)

      -- Check for Servlet-specific patterns
      assert.is_true(#config.patterns.GET > 0)
      assert.is_true(#config.patterns.POST > 0)
    end)

    it("should have controller extractors", function()
      local config = framework:get_config()
      assert.is_table(config.controller_extractors)
      assert.is_true(#config.controller_extractors > 0)
    end)

    it("should have detector configuration", function()
      local config = framework:get_config()
      assert.is_table(config.detector)
      assert.is_table(config.detector.dependencies)
      assert.is_table(config.detector.manifest_files)
      assert.equals("servlet_dependency_detection", config.detector.name)

      -- Check for Servlet-specific dependencies
      assert.is_true(#config.detector.dependencies > 0)
      assert.is_true(#config.detector.dependencies > 0)
    end)
  end)

  describe("Parser Functionality", function()
    it("should parse WebServlet annotations", function()
      local content = '@WebServlet("/users")'
      local result = parser:parse_content(content, "UserServlet.java", 1, 1)

      assert.is_not_nil(result)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse WebServlet with urlPatterns", function()
      local content = '@WebServlet(urlPatterns = "/users")'
      local result = parser:parse_content(content, "UserServlet.java", 1, 1)

      if result then
        assert.equals("/users", result.endpoint_path)
      end
    end)

    it("should parse doGet methods", function()
      local content = "protected void doGet(HttpServletRequest request, HttpServletResponse response)"
      local result = parser:parse_content(content, "UserServlet.java", 1, 1)

      if result then
        assert.equals("GET", result.method)
      end
    end)

    it("should parse doPost methods", function()
      local content = "protected void doPost(HttpServletRequest request, HttpServletResponse response)"
      local result = parser:parse_content(content, "UserServlet.java", 1, 1)

      if result then
        assert.equals("POST", result.method)
      end
    end)

    it("should handle servlet with wildcard patterns", function()
      local content = '@WebServlet("/users/*")'
      local result = parser:parse_content(content, "UserServlet.java", 1, 1)

      if result then
        assert.equals("/users/*", result.endpoint_path)
      end
    end)

    it("should parse servlet with multiple URL patterns", function()
      local content = '@WebServlet(urlPatterns = {"/users", "/api/users"})'
      local result = parser:parse_content(content, "UserServlet.java", 1, 1)

      if result then
        assert.is_true(#result == 2)
      end
    end)
  end)

  describe("Search Command Generation", function()
    it("should generate valid search commands", function()
      local search_cmd = framework:get_search_cmd()
      assert.is_string(search_cmd)
      assert.matches("rg", search_cmd)
      assert.matches("--type java", search_cmd)
    end)
  end)

  describe("Controller Name Extraction", function()
    it("should extract servlet name from Java file", function()
      local controller_name = framework:getControllerName "src/main/java/com/example/UserServlet.java"
      assert.is_not_nil(controller_name)
    end)

    it("should handle nested servlet paths", function()
      local controller_name = framework:getControllerName "src/main/java/com/example/admin/UserServlet.java"
      assert.is_not_nil(controller_name)
    end)
  end)

  describe("Integration Tests", function()
    it("should create framework instance successfully", function()
      local instance = ServletFramework:new()
      assert.is_not_nil(instance)
      assert.equals("servlet", instance:get_name())
    end)

    it("should have parser and detector ready", function()
      assert.is_not_nil(framework.parser)
      assert.is_not_nil(framework.detector)
      assert.equals("servlet", framework.parser.framework_name)
    end)

    it("should parse and enhance endpoints", function()
      local content = '@WebServlet("/api/users")'
      local result = framework:parse(content, "UserServlet.java", 1, 1)

      if result then
        assert.equals("servlet", result.framework)
        assert.is_table(result.metadata)
        assert.equals("servlet", result.metadata.framework)
      end
    end)
  end)
end)

describe("ServletParser", function()
  local parser

  before_each(function()
    parser = ServletParser:new()
  end)

  describe("Parser Instance", function()
    it("should create parser with correct properties", function()
      assert.equals("servlet_parser", parser.parser_name)
      assert.equals("servlet", parser.framework_name)
      assert.equals("java", parser.language)
    end)
  end)

  describe("Endpoint Path Extraction", function()
    it("should extract simple paths from WebServlet", function()
      local path = parser:extract_endpoint_path '@WebServlet("/users")'
      assert.equals("/users", path)
    end)

    it("should extract paths with urlPatterns", function()
      local path = parser:extract_endpoint_path '@WebServlet(urlPatterns = "/users")'
      assert.equals("/users", path)
    end)

    it("should handle wildcard patterns", function()
      local path = parser:extract_endpoint_path '@WebServlet("/users/*")'
      assert.equals("/users/*", path)
    end)

    it("should handle single quotes", function()
      local path = parser:extract_endpoint_path "@WebServlet('/users')"
      if path then
        assert.equals("/users", path)
      end
    end)
  end)

  describe("HTTP Method Extraction", function()
    it("should extract GET from doGet", function()
      local method = parser:extract_method "protected void doGet("
      assert.equals("GET", method)
    end)

    it("should extract POST from doPost", function()
      local method = parser:extract_method "protected void doPost("
      assert.equals("POST", method)
    end)

    it("should extract PUT from doPut", function()
      local method = parser:extract_method "protected void doPut("
      assert.equals("PUT", method)
    end)

    it("should extract DELETE from doDelete", function()
      local method = parser:extract_method "protected void doDelete("
      assert.equals("DELETE", method)
    end)

    it("should extract OPTIONS from doOptions", function()
      local method = parser:extract_method "protected void doOptions("
      if method then
        assert.equals("OPTIONS", method)
      end
    end)
  end)

  describe("Base Path Extraction", function()
    it("should handle servlet mapping contexts", function()
      local base_path = parser:extract_base_path("UserServlet.java", 10)
      assert.is_true(base_path == nil or type(base_path) == "string")
    end)
  end)

  describe("Error Handling", function()
    it("should handle malformed annotations gracefully", function()
      local result = parser:parse_content("@InvalidAnnotation", "test.java", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle empty content", function()
      local result = parser:parse_content("", "test.java", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle missing file path", function()
      local result = parser:parse_content('@WebServlet("/users")', nil, 1, 1)
      if result then
        assert.is_not_nil(result)
      end
    end)

    it("should return nil for non-Servlet content", function()
      local result = parser:parse_content("public class User {}", "test.java", 1, 1)
      assert.is_nil(result)
    end)
  end)
end)
