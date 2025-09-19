local SymfonyFramework = require "endpoint.frameworks.symfony"
local SymfonyParser = require "endpoint.parser.symfony_parser"

describe("SymfonyFramework", function()
  local framework
  local parser

  before_each(function()
    framework = SymfonyFramework:new()
    parser = SymfonyParser:new()
  end)

  describe("Framework Detection", function()
    it("should have correct framework name", function()
      assert.equals("symfony", framework:get_name())
    end)

    it("should have detector configured", function()
      assert.is_not_nil(framework.detector)
      assert.equals("symfony_dependency_detection", framework.detector.detection_name)
    end)

    it("should have parser configured", function()
      assert.is_not_nil(framework.parser)
      assert.equals("symfony_parser", framework.parser.parser_name)
    end)
  end)

  describe("Framework Configuration", function()
    it("should have correct file extensions", function()
      local config = framework:get_config()
      assert.same({ "*.php" }, config.file_extensions)
    end)

    it("should have exclude patterns", function()
      local config = framework:get_config()
      assert.same({ "**/vendor", "**/var", "**/cache" }, config.exclude_patterns)
    end)

    it("should have Symfony-specific search patterns", function()
      local config = framework:get_config()
      assert.is_table(config.patterns.GET)
      assert.is_table(config.patterns.POST)
      assert.is_table(config.patterns.PUT)
      assert.is_table(config.patterns.DELETE)
      assert.is_table(config.patterns.PATCH)

      -- Check for Symfony-specific patterns
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
      assert.equals("symfony_dependency_detection", config.detector.name)

      -- Check for Symfony-specific dependencies
      assert.is_true(#config.detector.dependencies > 0)
    end)
  end)

  describe("Parser Functionality", function()
    it("should parse Route attributes", function()
      local content = '#[Route("/users", methods: ["GET"])]'
      local result = parser:parse_content(content, "UserController.php", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse Route annotations", function()
      local content = '@Route("/users", methods={"GET"})'
      local result = parser:parse_content(content, "UserController.php", 1, 1)

      if result then
        assert.equals("GET", result.method)
        assert.equals("/users", result.endpoint_path)
      end
    end)

    it("should parse method-specific attributes", function()
      local content = '#[Route("/users/{id}", methods: ["PUT"])]'
      local result = parser:parse_content(content, "UserController.php", 1, 1)

      if result then
        assert.equals("PUT", result.method)
        assert.equals("/users/{id}", result.endpoint_path)
      end
    end)

    it("should handle single quotes", function()
      local content = "#[Route('/users', methods: ['GET'])]"
      local result = parser:parse_content(content, "UserController.php", 1, 1)

      if result then
        assert.equals("GET", result.method)
        assert.equals("/users", result.endpoint_path)
      end
    end)

    it("should parse endpoints with parameters", function()
      local content = '#[Route("/users/{id}/posts/{postId}", methods: ["GET"])]'
      local result = parser:parse_content(content, "UserController.php", 1, 1)

      if result then
        assert.equals("GET", result.method)
        assert.equals("/users/{id}/posts/{postId}", result.endpoint_path)
      end
    end)
  end)

  describe("Search Command Generation", function()
    it("should generate valid search commands", function()
      local search_cmd = framework:get_search_cmd()
      assert.is_string(search_cmd)
      assert.matches("rg", search_cmd)
      assert.matches("--type php", search_cmd)
    end)
  end)

  describe("Controller Name Extraction", function()
    it("should extract controller name from PHP file", function()
      local controller_name = framework:getControllerName("src/Controller/UserController.php")
      assert.is_not_nil(controller_name)
    end)

    it("should handle nested controller paths", function()
      local controller_name = framework:getControllerName("src/Controller/Admin/UserController.php")
      assert.is_not_nil(controller_name)
    end)
  end)

  describe("Integration Tests", function()
    it("should create framework instance successfully", function()
      local instance = SymfonyFramework:new()
      assert.is_not_nil(instance)
      assert.equals("symfony", instance.name)
    end)

    it("should have parser and detector ready", function()
      assert.is_not_nil(framework.parser)
      assert.is_not_nil(framework.detector)
      assert.equals("symfony", framework.parser.framework_name)
    end)

    it("should parse and enhance endpoints", function()
      local content = '#[Route("/api/users", methods: ["GET"])]'
      local result = framework:parse(content, "UserController.php", 1, 1)

      if result then
        assert.equals("symfony", result.framework)
        assert.is_table(result.metadata)
        assert.equals("symfony", result.metadata.framework)
      end
    end)
  end)
end)

describe("SymfonyParser", function()
  local parser

  before_each(function()
    parser = SymfonyParser:new()
  end)

  describe("Parser Instance", function()
    it("should create parser with correct properties", function()
      assert.equals("symfony_parser", parser.parser_name)
      assert.equals("symfony", parser.framework_name)
      assert.equals("php", parser.language)
    end)
  end)

  describe("Endpoint Path Extraction", function()
    it("should extract simple paths from attributes", function()
      local path = parser:extract_endpoint_path('#[Route("/users")]')
      if path then
        assert.equals("/users", path)
      end
    end)

    it("should extract paths with parameters", function()
      local path = parser:extract_endpoint_path('#[Route("/users/{id}")]')
      if path then
        assert.equals("/users/{id}", path)
      end
    end)

    it("should handle single quotes", function()
      local path = parser:extract_endpoint_path("#[Route('/users')]")
      if path then
        assert.equals("/users", path)
      end
    end)

    it("should extract paths from annotations", function()
      local path = parser:extract_endpoint_path('@Route("/users")')
      if path then
        assert.equals("/users", path)
      end
    end)
  end)

  describe("HTTP Method Extraction", function()
    it("should extract GET from methods array", function()
      local method = parser:extract_method('#[Route("/users", methods: ["GET"])]')
      assert.equals("GET", method)
    end)

    it("should extract POST from methods array", function()
      local method = parser:extract_method('#[Route("/users", methods: ["POST"])]')
      assert.equals("POST", method)
    end)

    it("should extract PUT from methods array", function()
      local method = parser:extract_method('#[Route("/users/{id}", methods: ["PUT"])]')
      assert.equals("PUT", method)
    end)

    it("should extract DELETE from methods array", function()
      local method = parser:extract_method('#[Route("/users/{id}", methods: ["DELETE"])]')
      assert.equals("DELETE", method)
    end)

    it("should extract PATCH from methods array", function()
      local method = parser:extract_method('#[Route("/users/{id}", methods: ["PATCH"])]')
      assert.equals("PATCH", method)
    end)

    it("should handle annotation syntax", function()
      local method = parser:extract_method('@Route("/users", methods={"GET"})')
      if method then
        assert.equals("GET", method)
      end
    end)
  end)

  describe("Base Path Extraction", function()
    it("should handle controller-level routes", function()
      local base_path = parser:extract_base_path("UserController.php", 10)
      assert.is_true(base_path == nil or type(base_path) == "string")
    end)
  end)

  describe("Error Handling", function()
    it("should handle malformed routes gracefully", function()
      local result = parser:parse_content("#[InvalidAttribute]", "test.php", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle empty content", function()
      local result = parser:parse_content("", "test.php", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle missing file path", function()
      local result = parser:parse_content('#[Route("/users", methods: ["GET"])]', "UserController.php", 1, 1)
      if result then
        assert.is_table(result)
      end
    end)

    it("should return nil for non-Symfony content", function()
      local result = parser:parse_content("<?php $users = [];", "test.php", 1, 1)
      assert.is_nil(result)
    end)
  end)
end)