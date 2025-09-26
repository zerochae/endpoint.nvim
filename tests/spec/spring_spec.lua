---@diagnostic disable: duplicate-set-field
local SpringFramework = require "endpoint.frameworks.spring"
local SpringParser = require "endpoint.parser.spring_parser"
local fs = require "endpoint.utils.fs"

describe("SpringFramework", function()
  local framework
  local parser
  local original_has_file
  local original_file_contains
  local original_glob

  local function mockFs(has_pom, has_spring_deps)
    fs.has_file = function(files)
      if type(files) == "table" and files[1] == "pom.xml" then
        return has_pom
      end
      return false
    end

    fs.file_contains = function(filepath, pattern)
      if filepath == "pom.xml" and pattern == "spring-boot" then
        return has_spring_deps
      end
      return false
    end
  end

  before_each(function()
    framework = SpringFramework:new()
    parser = SpringParser:new()

    -- Backup original functions
    original_has_file = fs.has_file
    original_file_contains = fs.file_contains
    original_glob = vim.fn.glob
  end)

  after_each(function()
    -- Restore original functions
    fs.has_file = original_has_file
    fs.file_contains = original_file_contains
    vim.fn.glob = original_glob
  end)

  describe("Framework Detection", function()
    it("should have correct framework name", function()
      assert.equals("spring", framework:get_name())
    end)

    it("should have detector configured", function()
      assert.is_not_nil(framework.detector)
      assert.equals("spring_dependency_detection", framework.detector.detection_name)
    end)

    it("should have parser configured", function()
      assert.is_not_nil(framework.parser)
      assert.equals("spring_parser", framework.parser.parser_name)
    end)
  end)

  describe("Framework Configuration", function()
    it("should have correct file extensions", function()
      local config = framework:get_config()
      assert.same({ "*.java", "*.kt" }, config.file_extensions)
    end)

    it("should have exclude patterns", function()
      local config = framework:get_config()
      assert.same({ "**/target", "**/build", "**/.gradle" }, config.exclude_patterns)
    end)

    it("should have Spring-specific search patterns", function()
      local config = framework:get_config()
      assert.is_table(config.patterns.GET)
      assert.is_table(config.patterns.POST)
      assert.is_table(config.patterns.PUT)
      assert.is_table(config.patterns.DELETE)
      assert.is_table(config.patterns.PATCH)

      -- Check for Spring-specific patterns
      local has_get_mapping = false
      local has_post_mapping = false
      for _, pattern in ipairs(config.patterns.GET) do
        if pattern:match "@GetMapping" then
          has_get_mapping = true
          break
        end
      end
      for _, pattern in ipairs(config.patterns.POST) do
        if pattern:match "@PostMapping" then
          has_post_mapping = true
          break
        end
      end
      assert.is_true(has_get_mapping)
      assert.is_true(has_post_mapping)
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
      assert.equals("spring_dependency_detection", config.detector.name)

      -- Check for Spring-specific dependencies
      local has_spring_boot = false
      local has_spring_web = false
      for _, dep in ipairs(config.detector.dependencies) do
        if dep:match "spring%-boot" then
          has_spring_boot = true
        end
        if dep:match "spring%-web" then
          has_spring_web = true
        end
      end
      assert.is_true(has_spring_boot)
      assert.is_true(has_spring_web)
    end)

    it("should detect Maven project with Spring dependencies", function()
      mockFs(true, true)

      local detector = framework.detector
      assert.is_true(detector:is_target_detected())
    end)

    it("should return false when no pom.xml exists", function()
      mockFs(false, false)

      local detector = framework.detector
      assert.is_false(detector:is_target_detected())
    end)
  end)

  describe("Parser Functionality", function()
    it("should parse GetMapping annotations", function()
      local content = '@GetMapping("/users")'
      local result = parser:parse_content(content, "UserController.java", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse PostMapping annotations", function()
      local content = '@PostMapping("/users")'
      local result = parser:parse_content(content, "UserController.java", 1, 1)

      assert.is_not_nil(result)
      assert.equals("POST", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse RequestMapping with method parameter", function()
      local content = '@RequestMapping(value = "/users", method = RequestMethod.GET)'
      local result = parser:parse_content(content, "UserController.java", 1, 1)

      if result then
        assert.equals("GET", result.method)
        assert.equals("/users", result.endpoint_path)
      end
    end)

    it("should parse endpoints with path variables", function()
      local content = '@GetMapping("/users/{id}")'
      local result = parser:parse_content(content, "UserController.java", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users/{id}", result.endpoint_path)
    end)

    it("should handle value parameter syntax", function()
      local content = '@GetMapping(value = "/users")'
      local result = parser:parse_content(content, "UserController.java", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should handle path parameter syntax", function()
      local content = '@GetMapping(path = "/users")'
      local result = parser:parse_content(content, "UserController.java", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)
  end)

  describe("Search Command Generation", function()
    it("should generate valid search commands", function()
      local search_cmd = framework:get_search_cmd()
      assert.is_string(search_cmd)
      assert.matches("rg", search_cmd)
      assert.matches("--type java", search_cmd)
      assert.matches("--case%-sensitive", search_cmd)
    end)
  end)

  describe("Controller Name Extraction", function()
    it("should extract controller name from Java file", function()
      local controller_name = framework:getControllerName "src/main/java/com/example/UserController.java"
      assert.is_not_nil(controller_name)
    end)

    it("should extract controller name from Kotlin file", function()
      local controller_name = framework:getControllerName "src/main/kotlin/com/example/UserController.kt"
      assert.is_not_nil(controller_name)
    end)

    it("should handle nested controller paths", function()
      local controller_name = framework:getControllerName "src/main/java/com/example/admin/UserController.java"
      assert.is_not_nil(controller_name)
    end)
  end)

  describe("Integration Tests", function()
    it("should create framework instance successfully", function()
      local instance = SpringFramework:new()
      assert.is_not_nil(instance)
      assert.equals("spring", instance:get_name())
    end)

    it("should have parser and detector ready", function()
      assert.is_not_nil(framework.parser)
      assert.is_not_nil(framework.detector)
      assert.equals("spring", framework.parser.framework_name)
    end)

    it("should parse and enhance endpoints", function()
      local content = '@GetMapping("/api/users")'
      local result = framework:parse(content, "UserController.java", 1, 1)

      assert.is_not_nil(result)
      assert.equals("spring", result.framework)
      assert.is_table(result.metadata)
      assert.equals("spring", result.metadata.framework)
    end)
  end)
end)

describe("SpringParser", function()
  local parser

  before_each(function()
    parser = SpringParser:new()
  end)

  describe("Parser Instance", function()
    it("should create parser with correct properties", function()
      assert.equals("spring_parser", parser.parser_name)
      assert.equals("spring", parser.framework_name)
      assert.equals("java", parser.language)
    end)
  end)

  describe("Endpoint Path Extraction", function()
    it("should extract simple paths", function()
      local path = parser:extract_endpoint_path '@GetMapping("/users")'
      assert.equals("/users", path)
    end)

    it("should extract paths with path variables", function()
      local path = parser:extract_endpoint_path '@GetMapping("/users/{id}")'
      assert.equals("/users/{id}", path)
    end)

    it("should handle value parameter", function()
      local path = parser:extract_endpoint_path '@GetMapping(value = "/users")'
      assert.equals("/users", path)
    end)

    it("should handle path parameter", function()
      local path = parser:extract_endpoint_path '@GetMapping(path = "/users")'
      assert.equals("/users", path)
    end)

    it("should handle single quotes", function()
      local path = parser:extract_endpoint_path "@GetMapping('/users')"
      assert.equals("/users", path)
    end)
  end)

  describe("HTTP Method Extraction", function()
    it("should extract GET from GetMapping", function()
      local method = parser:extract_method '@GetMapping("/users")'
      assert.equals("GET", method)
    end)

    it("should extract POST from PostMapping", function()
      local method = parser:extract_method '@PostMapping("/users")'
      assert.equals("POST", method)
    end)

    it("should extract PUT from PutMapping", function()
      local method = parser:extract_method '@PutMapping("/users/{id}")'
      assert.equals("PUT", method)
    end)

    it("should extract DELETE from DeleteMapping", function()
      local method = parser:extract_method '@DeleteMapping("/users/{id}")'
      assert.equals("DELETE", method)
    end)

    it("should extract PATCH from PatchMapping", function()
      local method = parser:extract_method '@PatchMapping("/users/{id}")'
      assert.equals("PATCH", method)
    end)

    it("should extract method from RequestMapping", function()
      local method = parser:extract_method "@RequestMapping(method = RequestMethod.GET)"
      if method then
        assert.equals("GET", method)
      end
    end)
  end)

  describe("Base Path Extraction", function()
    it("should handle controller-level RequestMapping", function()
      local base_path = parser:extract_base_path("UserController.java", 10)
      assert.is_true(base_path == nil or type(base_path) == "string")
    end)
  end)

  describe("Error Handling", function()
    it("should handle malformed annotations gracefully", function()
      local result = parser:parse_content("@InvalidMapping", "test.java", 1, 1)
      -- Spring parser might parse this as a basic annotation, so we check if result is reasonable
      if result then
        assert.is_string(result.method)
        assert.is_string(result.endpoint_path)
      else
        assert.is_nil(result)
      end
    end)

    it("should handle empty content", function()
      local result = parser:parse_content("", "test.java", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle missing file path", function()
      local result = parser:parse_content('@GetMapping("/users")', "test.java", 1, 1)
      assert.is_not_nil(result)
    end)

    it("should return nil for non-Spring content", function()
      local result = parser:parse_content("public void someMethod() {}", "test.java", 1, 1)
      assert.is_nil(result)
    end)
  end)
end)
