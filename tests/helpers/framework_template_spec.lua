-- Template for framework tests - copy and customize for each framework
-- Replace FRAMEWORK_NAME with actual framework name (e.g., "spring", "express")
-- Replace FrameworkClass with actual class (e.g., SpringFramework, ExpressFramework)
-- Replace ParserClass with actual parser (e.g., SpringParser, ExpressParser)

local FrameworkClass = require "endpoint.frameworks.FRAMEWORK_NAME"
local ParserClass = require "endpoint.parser.FRAMEWORK_NAME_parser"

describe("FRAMEWORK_NAMEFramework", function()
  local framework
  local parser

  before_each(function()
    framework = FrameworkClass:new()
    parser = ParserClass:new()
  end)

  describe("Framework Detection", function()
    it("should have correct framework name", function()
      assert.equals("FRAMEWORK_NAME", framework:get_name())
    end)

    it("should have detector configured", function()
      assert.is_not_nil(framework.detector)
      assert.equals("FRAMEWORK_NAME_dependency_detection", framework.detector.detection_name)
    end)

    it("should have parser configured", function()
      assert.is_not_nil(framework.parser)
      assert.equals("FRAMEWORK_NAME_parser", framework.parser.parser_name)
    end)
  end)

  describe("Framework Configuration", function()
    it("should have correct file extensions", function()
      local config = framework:get_config()
      assert.is_table(config.file_extensions)
      assert.is_true(#config.file_extensions > 0)
      -- Example: assert.same({ "*.java", "*.kt" }, config.file_extensions)
    end)

    it("should have exclude patterns", function()
      local config = framework:get_config()
      assert.is_table(config.exclude_patterns)
      -- Example: assert.same({ "**/target", "**/build" }, config.exclude_patterns)
    end)

    it("should have framework-specific search patterns", function()
      local config = framework:get_config()
      assert.is_table(config.patterns.GET)
      assert.is_table(config.patterns.POST)
      assert.is_table(config.patterns.PUT)
      assert.is_table(config.patterns.DELETE)
      assert.is_table(config.patterns.PATCH)
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
      assert.is_string(config.detector.name)
    end)
  end)

  describe("Parser Functionality", function()
    -- Customize these tests based on your framework's patterns
    it("should parse basic endpoint definitions", function()
      -- Example for annotation-based frameworks:
      -- local content = '@GetMapping("/users")'
      -- Example for method-based frameworks:
      -- local content = 'app.get("/users", handler)'
      local content = "REPLACE_WITH_FRAMEWORK_PATTERN"
      local result = parser:parse_content(content, "test.ext", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse endpoints with parameters", function()
      local content = "REPLACE_WITH_PARAMETERIZED_PATTERN" -- e.g., '@GetMapping("/users/{id}")'
      local result = parser:parse_content(content, "test.ext", 1, 1)

      if result then
        assert.equals("GET", result.method)
        assert.matches("/users", result.endpoint_path)
      end
    end)

    it("should parse POST endpoints", function()
      local content = "REPLACE_WITH_POST_PATTERN" -- e.g., '@PostMapping("/users")'
      local result = parser:parse_content(content, "test.ext", 1, 1)

      if result then
        assert.equals("POST", result.method)
        assert.equals("/users", result.endpoint_path)
      end
    end)

    it("should handle complex endpoint patterns", function()
      -- Add framework-specific complex patterns
      local content = "REPLACE_WITH_COMPLEX_PATTERN"
      local result = parser:parse_content(content, "test.ext", 1, 1)

      if result then
        assert.is_string(result.method)
        assert.is_string(result.endpoint_path)
      end
    end)
  end)

  describe("Search Command Generation", function()
    it("should generate valid search commands", function()
      local search_cmd = framework:get_search_cmd()
      assert.is_string(search_cmd)
      assert.matches("rg", search_cmd)
      -- Check for framework-specific flags
      -- Example: assert.matches("--type java", search_cmd)
    end)
  end)

  describe("Controller Name Extraction", function()
    it("should extract controller name from file path", function()
      -- Use framework-specific file path pattern
      local controller_name = framework:getControllerName("path/to/UserController.ext")
      -- This might return nil if no extractors match
      assert.is_true(controller_name == nil or type(controller_name) == "string")
    end)

    it("should handle nested controller paths", function()
      local controller_name = framework:getControllerName("path/to/nested/UserController.ext")
      assert.is_true(controller_name == nil or type(controller_name) == "string")
    end)
  end)

  describe("Integration Tests", function()
    it("should create framework instance successfully", function()
      local instance = FrameworkClass:new()
      assert.is_not_nil(instance)
      assert.equals("FRAMEWORK_NAME", instance.name)
    end)

    it("should have parser and detector ready", function()
      assert.is_not_nil(framework.parser)
      assert.is_not_nil(framework.detector)
      assert.equals("FRAMEWORK_NAME", framework.parser.framework_name)
    end)

    it("should parse and enhance endpoints", function()
      local content = "REPLACE_WITH_FRAMEWORK_PATTERN"
      local result = framework:parse(content, "test.ext", 1, 1)

      if result then
        assert.equals("FRAMEWORK_NAME", result.framework)
        assert.is_table(result.metadata)
        assert.equals("FRAMEWORK_NAME", result.metadata.framework)
      end
    end)

    it("should detect framework properly", function()
      -- Note: This test requires proper test fixtures
      -- local detected = framework:detect()
      -- assert.is_boolean(detected)
    end)
  end)
end)

describe("FRAMEWORK_NAMEParser", function()
  local parser

  before_each(function()
    parser = ParserClass:new()
  end)

  describe("Parser Instance", function()
    it("should create parser with correct properties", function()
      assert.equals("FRAMEWORK_NAME_parser", parser.parser_name)
      assert.equals("FRAMEWORK_NAME", parser.framework_name)
      assert.equals("REPLACE_WITH_LANGUAGE", parser.language) -- e.g., "java", "javascript", "python"
    end)
  end)

  describe("Endpoint Path Extraction", function()
    it("should extract simple paths", function()
      -- Test framework-specific path extraction
      local path = parser:extract_endpoint_path('PATTERN_WITH_SIMPLE_PATH')
      if path then
        assert.equals("/users", path)
      end
    end)

    it("should extract paths with parameters", function()
      local path = parser:extract_endpoint_path('PATTERN_WITH_PARAMETER_PATH')
      if path then
        assert.matches("/users", path)
      end
    end)

    it("should handle different quote styles", function()
      -- Test if framework supports different quote styles
      local path1 = parser:extract_endpoint_path("PATTERN_WITH_SINGLE_QUOTES")
      local path2 = parser:extract_endpoint_path("PATTERN_WITH_DOUBLE_QUOTES")

      if path1 and path2 then
        assert.equals(path1, path2)
      end
    end)
  end)

  describe("HTTP Method Extraction", function()
    it("should extract GET method", function()
      local method = parser:extract_method('GET_PATTERN')
      if method then
        assert.equals("GET", method)
      end
    end)

    it("should extract POST method", function()
      local method = parser:extract_method('POST_PATTERN')
      if method then
        assert.equals("POST", method)
      end
    end)

    it("should extract PUT method", function()
      local method = parser:extract_method('PUT_PATTERN')
      if method then
        assert.equals("PUT", method)
      end
    end)

    it("should extract DELETE method", function()
      local method = parser:extract_method('DELETE_PATTERN')
      if method then
        assert.equals("DELETE", method)
      end
    end)

    it("should extract PATCH method", function()
      local method = parser:extract_method('PATCH_PATTERN')
      if method then
        assert.equals("PATCH", method)
      end
    end)
  end)

  describe("Base Path Extraction", function()
    it("should handle base path contexts", function()
      local base_path = parser:extract_base_path("test.ext", 10)
      assert.is_true(base_path == nil or type(base_path) == "string")
    end)
  end)

  describe("Error Handling", function()
    it("should handle malformed content gracefully", function()
      local result = parser:parse_content("invalid content", "test.ext", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle empty content", function()
      local result = parser:parse_content("", "test.ext", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle missing file path", function()
      local result = parser:parse_content('VALID_PATTERN', nil, 1, 1)
      -- Should still attempt to parse content
      assert.is_true(result == nil or type(result) == "table")
    end)

    it("should return nil for unrecognized patterns", function()
      local result = parser:parse_content("completely unrelated content", "test.ext", 1, 1)
      assert.is_nil(result)
    end)
  end)
end)

-- Usage Instructions:
-- 1. Copy this template to a new file named {framework}_spec.lua
-- 2. Replace all FRAMEWORK_NAME with your framework name
-- 3. Replace all REPLACE_WITH_* placeholders with actual patterns
-- 4. Update file extensions (.ext -> .java, .py, .js, etc.)
-- 5. Add framework-specific test cases
-- 6. Remove or modify tests that don't apply to your framework
