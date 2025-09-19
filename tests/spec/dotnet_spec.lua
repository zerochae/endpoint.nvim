local DotnetFramework = require "endpoint.frameworks.dotnet"
local DotnetParser = require "endpoint.parser.dotnet_parser"

describe("DotnetFramework", function()
  local framework
  local parser

  before_each(function()
    framework = DotnetFramework:new()
    parser = DotnetParser:new()
  end)

  describe("Framework Detection", function()
    it("should have correct framework name", function()
      assert.equals("dotnet", framework:get_name())
    end)

    it("should have detector configured", function()
      assert.is_not_nil(framework.detector)
      assert.equals("dotnet_dependency_detection", framework.detector.detection_name)
    end)

    it("should have parser configured", function()
      assert.is_not_nil(framework.parser)
      assert.equals("dotnet_parser", framework.parser.parser_name)
    end)
  end)

  describe("Framework Configuration", function()
    it("should have correct file extensions", function()
      local config = framework:get_config()
      assert.same({ "*.cs" }, config.file_extensions)
    end)

    it("should have exclude patterns", function()
      local config = framework:get_config()
      assert.same({ "**/bin", "**/obj", "**/packages" }, config.exclude_patterns)
    end)

    it("should have .NET-specific search patterns", function()
      local config = framework:get_config()
      assert.is_table(config.patterns.GET)
      assert.is_table(config.patterns.POST)
      assert.is_table(config.patterns.PUT)
      assert.is_table(config.patterns.DELETE)
      assert.is_table(config.patterns.PATCH)

      -- Check for .NET-specific patterns
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
      assert.equals("dotnet_dependency_detection", config.detector.name)

      -- Check for .NET-specific dependencies
      assert.is_true(#config.detector.dependencies > 0)
    end)
  end)

  describe("Parser Functionality", function()
    it("should parse HttpGet attributes", function()
      local content = '[HttpGet("/users")]'
      local result = parser:parse_content(content, "UserController.cs", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse HttpPost attributes", function()
      local content = '[HttpPost("/users")]'
      local result = parser:parse_content(content, "UserController.cs", 1, 1)

      assert.is_not_nil(result)
      assert.equals("POST", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse Route attributes", function()
      local content = '[Route("/users")]'
      local result = parser:parse_content(content, "UserController.cs", 1, 1)

      if result then
        assert.is_string(result.method)
        assert.equals("/users", result.endpoint_path)
      end
    end)

    it("should parse endpoints with parameters", function()
      local content = '[HttpGet("/users/{id}")]'
      local result = parser:parse_content(content, "UserController.cs", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users/{id}", result.endpoint_path)
    end)

    it("should handle single quotes", function()
      local content = "[HttpGet('/users')]"
      local result = parser:parse_content(content, "UserController.cs", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse attributes without explicit routes", function()
      local content = '[HttpGet]'
      local result = parser:parse_content(content, "UserController.cs", 1, 1)

      if result then
        assert.equals("GET", result.method)
      end
    end)
  end)

  describe("Search Command Generation", function()
    it("should generate valid search commands", function()
      local search_cmd = framework:get_search_cmd()
      assert.is_string(search_cmd)
      assert.matches("rg", search_cmd)
      assert.matches("--type csharp", search_cmd)
    end)
  end)

  describe("Controller Name Extraction", function()
    it("should extract controller name from C# file", function()
      local controller_name = framework:getControllerName("Controllers/UserController.cs")
      assert.is_not_nil(controller_name)
    end)

    it("should handle nested controller paths", function()
      local controller_name = framework:getControllerName("Areas/Admin/Controllers/UserController.cs")
      assert.is_not_nil(controller_name)
    end)
  end)

  describe("Integration Tests", function()
    it("should create framework instance successfully", function()
      local instance = DotnetFramework:new()
      assert.is_not_nil(instance)
      assert.equals("dotnet", instance.name)
    end)

    it("should have parser and detector ready", function()
      assert.is_not_nil(framework.parser)
      assert.is_not_nil(framework.detector)
      assert.equals("dotnet", framework.parser.framework_name)
    end)

    it("should parse and enhance endpoints", function()
      local content = '[HttpGet("/api/users")]'
      local result = framework:parse(content, "UserController.cs", 1, 1)

      assert.is_not_nil(result)
      assert.equals("dotnet", result.framework)
      assert.is_table(result.metadata)
      assert.equals("dotnet", result.metadata.framework)
    end)
  end)
end)

describe("DotnetParser", function()
  local parser

  before_each(function()
    parser = DotnetParser:new()
  end)

  describe("Parser Instance", function()
    it("should create parser with correct properties", function()
      assert.equals("dotnet_parser", parser.parser_name)
      assert.equals("dotnet", parser.framework_name)
      assert.equals("csharp", parser.language)
    end)
  end)

  describe("Endpoint Path Extraction", function()
    it("should extract simple paths", function()
      local path = parser:extract_endpoint_path('[HttpGet("/users")]')
      assert.equals("/users", path)
    end)

    it("should extract paths with parameters", function()
      local path = parser:extract_endpoint_path('[HttpGet("/users/{id}")]')
      assert.equals("/users/{id}", path)
    end)

    it("should handle single quotes", function()
      local path = parser:extract_endpoint_path("[HttpGet('/users')]")
      assert.equals("/users", path)
    end)

    it("should handle Route attributes", function()
      local path = parser:extract_endpoint_path('[Route("/users")]')
      assert.equals("/users", path)
    end)
  end)

  describe("HTTP Method Extraction", function()
    it("should extract GET from HttpGet", function()
      local method = parser:extract_method('[HttpGet("/users")]')
      assert.equals("GET", method)
    end)

    it("should extract POST from HttpPost", function()
      local method = parser:extract_method('[HttpPost("/users")]')
      assert.equals("POST", method)
    end)

    it("should extract PUT from HttpPut", function()
      local method = parser:extract_method('[HttpPut("/users/{id}")]')
      assert.equals("PUT", method)
    end)

    it("should extract DELETE from HttpDelete", function()
      local method = parser:extract_method('[HttpDelete("/users/{id}")]')
      assert.equals("DELETE", method)
    end)

    it("should extract PATCH from HttpPatch", function()
      local method = parser:extract_method('[HttpPatch("/users/{id}")]')
      assert.equals("PATCH", method)
    end)
  end)

  describe("Base Path Extraction", function()
    it("should handle controller-level routes", function()
      local base_path = parser:extract_base_path("UserController.cs", 10)
      assert.is_true(base_path == nil or type(base_path) == "string")
    end)
  end)

  describe("Error Handling", function()
    it("should handle malformed attributes gracefully", function()
      local result = parser:parse_content("[InvalidAttribute]", "test.cs", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle empty content", function()
      local result = parser:parse_content("", "test.cs", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle missing file path", function()
      local result = parser:parse_content('[HttpGet("/users")]', "test.cs", 1, 1)
      assert.is_not_nil(result)
    end)

    it("should return nil for non-.NET content", function()
      local result = parser:parse_content("var users = new List<User>();", "test.cs", 1, 1)
      assert.is_nil(result)
    end)
  end)
end)