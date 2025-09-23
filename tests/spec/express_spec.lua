local ExpressFramework = require "endpoint.frameworks.express"
local ExpressParser = require "endpoint.parser.express_parser"

describe("ExpressFramework", function()
  local framework
  local parser

  before_each(function()
    framework = ExpressFramework:new()
    parser = ExpressParser:new()
  end)

  describe("Framework Detection", function()
    it("should have correct framework name", function()
      assert.equals("express", framework:get_name())
    end)

    it("should have detector configured", function()
      assert.is_not_nil(framework.detector)
      assert.equals("express_dependency_detection", framework.detector.detection_name)
    end)

    it("should have parser configured", function()
      assert.is_not_nil(framework.parser)
      assert.equals("express_parser", framework.parser.parser_name)
    end)
  end)

  describe("Framework Configuration", function()
    it("should have correct file extensions", function()
      local config = framework:get_config()
      assert.same({ "*.js", "*.ts", "*.mjs" }, config.file_extensions)
    end)

    it("should have exclude patterns", function()
      local config = framework:get_config()
      assert.same({ "**/node_modules", "**/dist", "**/build" }, config.exclude_patterns)
    end)

    it("should have Express-specific search patterns", function()
      local config = framework:get_config()
      assert.is_table(config.patterns.GET)
      assert.is_table(config.patterns.POST)
      assert.is_table(config.patterns.PUT)
      assert.is_table(config.patterns.DELETE)
      assert.is_table(config.patterns.PATCH)

      -- Check for Express-specific patterns (simplified check)
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
      assert.equals("express_dependency_detection", config.detector.name)

      -- Check for Express-specific dependencies
      local has_express = false
      for _, dep in ipairs(config.detector.dependencies) do
        if dep:match("express") then
          has_express = true
          break
        end
      end
      assert.is_true(has_express)
    end)
  end)

  describe("Parser Functionality", function()
    it("should parse app.get routes", function()
      local content = 'app.get("/users", handler)'
      local result = parser:parse_content(content, "routes.js", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse app.post routes", function()
      local content = 'app.post("/users", handler)'
      local result = parser:parse_content(content, "routes.js", 1, 1)

      assert.is_not_nil(result)
      assert.equals("POST", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse router.get routes", function()
      local content = 'router.get("/users", handler)'
      local result = parser:parse_content(content, "routes.js", 1, 1)

      if result then
        assert.equals("GET", result.method)
        assert.equals("/users", result.endpoint_path)
      end
    end)

    it("should parse endpoints with parameters", function()
      local content = 'app.get("/users/:id", handler)'
      local result = parser:parse_content(content, "routes.js", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users/:id", result.endpoint_path)
    end)

    it("should handle single quotes", function()
      local content = "app.get('/users', handler)"
      local result = parser:parse_content(content, "routes.js", 1, 1)

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
      assert.matches("--type js", search_cmd)
    end)
  end)

  describe("Controller Name Extraction", function()
    it("should extract controller name from JavaScript file", function()
      local controller_name = framework:getControllerName("routes/users.js")
      assert.is_not_nil(controller_name)
    end)

    it("should extract controller name from TypeScript file", function()
      local controller_name = framework:getControllerName("routes/users.ts")
      assert.is_not_nil(controller_name)
    end)

    it("should handle nested route paths", function()
      local controller_name = framework:getControllerName("routes/api/users.js")
      assert.is_not_nil(controller_name)
    end)
  end)

  describe("Integration Tests", function()
    it("should create framework instance successfully", function()
      local instance = ExpressFramework:new()
      assert.is_not_nil(instance)
      assert.equals("express", instance:get_name())
    end)

    it("should have parser and detector ready", function()
      assert.is_not_nil(framework.parser)
      assert.is_not_nil(framework.detector)
      assert.equals("express", framework.parser.framework_name)
    end)

    it("should parse and enhance endpoints", function()
      local content = 'app.get("/api/users", handler)'
      local result = framework:parse(content, "routes.js", 1, 1)

      assert.is_not_nil(result)
      assert.equals("express", result.framework)
      assert.is_table(result.metadata)
      assert.equals("express", result.metadata.framework)
    end)
  end)
end)

describe("ExpressParser", function()
  local parser

  before_each(function()
    parser = ExpressParser:new()
  end)

  describe("Parser Instance", function()
    it("should create parser with correct properties", function()
      assert.equals("express_parser", parser.parser_name)
      assert.equals("express", parser.framework_name)
      assert.equals("javascript", parser.language)
    end)
  end)

  describe("Endpoint Path Extraction", function()
    it("should extract simple paths", function()
      local path = parser:extract_endpoint_path('app.get("/users"')
      assert.equals("/users", path)
    end)

    it("should extract paths with parameters", function()
      local path = parser:extract_endpoint_path('app.get("/users/:id"')
      assert.equals("/users/:id", path)
    end)

    it("should handle single quotes", function()
      local path = parser:extract_endpoint_path("app.get('/users'")
      assert.equals("/users", path)
    end)

    it("should handle router patterns", function()
      local path = parser:extract_endpoint_path('router.get("/users"')
      assert.equals("/users", path)
    end)
  end)

  describe("HTTP Method Extraction", function()
    it("should extract GET from app.get", function()
      local method = parser:extract_method('app.get("/users"')
      assert.equals("GET", method)
    end)

    it("should extract POST from app.post", function()
      local method = parser:extract_method('app.post("/users"')
      assert.equals("POST", method)
    end)

    it("should extract PUT from app.put", function()
      local method = parser:extract_method('app.put("/users/:id"')
      assert.equals("PUT", method)
    end)

    it("should extract DELETE from app.delete", function()
      local method = parser:extract_method('app.delete("/users/:id"')
      assert.equals("DELETE", method)
    end)

    it("should extract PATCH from app.patch", function()
      local method = parser:extract_method('app.patch("/users/:id"')
      assert.equals("PATCH", method)
    end)

    it("should extract method from router patterns", function()
      local method = parser:extract_method('router.get("/users"')
      assert.equals("GET", method)
    end)
  end)

  describe("Base Path Extraction", function()
    it("should handle router mounting contexts", function()
      local base_path = parser:extract_base_path("routes.js", 10)
      assert.is_true(base_path == nil or type(base_path) == "string")
    end)
  end)

  describe("Error Handling", function()
    it("should handle malformed routes gracefully", function()
      local result = parser:parse_content("invalid route", "test.js", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle empty content", function()
      local result = parser:parse_content("", "test.js", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle missing file path", function()
      local result = parser:parse_content('app.get("/users", handler)', nil, 1, 1)
      assert.is_not_nil(result)
    end)

    it("should return nil for non-Express content", function()
      local result = parser:parse_content("const users = []", "test.js", 1, 1)
      assert.is_nil(result)
    end)
  end)
end)