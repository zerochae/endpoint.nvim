local ReactRouterFramework = require "endpoint.frameworks.react_router"
local ReactRouterParser = require "endpoint.parser.react_router_parser"

describe("ReactRouterFramework", function()
  local framework
  local parser

  before_each(function()
    framework = ReactRouterFramework:new()
    parser = ReactRouterParser:new()
  end)

  describe("Framework Detection", function()
    it("should have correct framework name", function()
      assert.equals("react_router", framework:get_name())
    end)

    it("should have detector configured", function()
      assert.is_not_nil(framework.detector)
      assert.equals("react_router_dependency_detection", framework.detector.detection_name)
    end)

    it("should have parser configured", function()
      assert.is_not_nil(framework.parser)
      assert.equals("react_router_parser", framework.parser.parser_name)
    end)
  end)

  describe("Framework Configuration", function()
    it("should have correct file extensions", function()
      local config = framework:get_config()
      assert.same({ "*.js", "*.jsx", "*.ts", "*.tsx" }, config.file_extensions)
    end)

    it("should have exclude patterns", function()
      local config = framework:get_config()
      assert.same({ "**/node_modules", "**/dist", "**/build", "**/.next" }, config.exclude_patterns)
    end)

    it("should have React Router-specific search patterns", function()
      local config = framework:get_config()
      assert.is_table(config.patterns.GET)

      -- Check for React Router-specific patterns (routes are typically GET-based navigation)
      assert.is_true(#config.patterns.GET > 0)
      assert.is_true(#config.patterns.GET > 0)
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
      assert.equals("react_router_dependency_detection", config.detector.name)

      -- Check for React Router-specific dependencies
      assert.is_true(#config.detector.dependencies > 0)
      assert.is_true(#config.detector.dependencies > 0)
    end)
  end)

  describe("Parser Functionality", function()
    it("should parse Route components", function()
      local content = '<Route path="/users" component={Users} />'
      local result = parser:parse_content(content, "App.jsx", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method) -- Routes are typically GET navigation
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse Route with element prop", function()
      local content = '<Route path="/users" element={<Users />} />'
      local result = parser:parse_content(content, "App.jsx", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse nested routes", function()
      local content = '<Route path="/users/:id" element={<UserDetail />} />'
      local result = parser:parse_content(content, "App.jsx", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users/:id", result.endpoint_path)
    end)

    it("should handle single quotes", function()
      local content = "<Route path='/users' component={Users} />"
      local result = parser:parse_content(content, "App.jsx", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse routes with exact prop", function()
      local content = '<Route exact path="/users" component={Users} />'
      local result = parser:parse_content(content, "App.jsx", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse router configuration objects", function()
      local content = '{ path: "/users", component: Users }'
      local result = parser:parse_content(content, "routes.js", 1, 1)

      if result then
        assert.equals("GET", result.method)
        assert.equals("/users", result.endpoint_path)
      end
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
    it("should extract component name from JavaScript file", function()
      local controller_name = framework:getControllerName("src/components/Users.jsx")
      assert.is_not_nil(controller_name)
    end)

    it("should extract component name from TypeScript file", function()
      local controller_name = framework:getControllerName("src/components/Users.tsx")
      assert.is_not_nil(controller_name)
    end)

    it("should handle nested component paths", function()
      local controller_name = framework:getControllerName("src/pages/admin/Users.jsx")
      assert.is_not_nil(controller_name)
    end)
  end)

  describe("Integration Tests", function()
    it("should create framework instance successfully", function()
      local instance = ReactRouterFramework:new()
      assert.is_not_nil(instance)
      assert.equals("react_router", instance.name)
    end)

    it("should have parser and detector ready", function()
      assert.is_not_nil(framework.parser)
      assert.is_not_nil(framework.detector)
      assert.equals("react_router", framework.parser.framework_name)
    end)

    it("should parse and enhance endpoints", function()
      local content = '<Route path="/api/users" element={<Users />} />'
      local result = framework:parse(content, "App.jsx", 1, 1)

      assert.is_not_nil(result)
      assert.equals("react_router", result.framework)
      assert.is_table(result.metadata)
      assert.equals("react_router", result.metadata.framework)
    end)
  end)
end)

describe("ReactRouterParser", function()
  local parser

  before_each(function()
    parser = ReactRouterParser:new()
  end)

  describe("Parser Instance", function()
    it("should create parser with correct properties", function()
      assert.equals("react_router_parser", parser.parser_name)
      assert.equals("react_router", parser.framework_name)
      assert.equals("javascript", parser.language)
    end)
  end)

  describe("Endpoint Path Extraction", function()
    it("should extract simple paths from Route", function()
      local path = parser:extract_endpoint_path('<Route path="/users"')
      assert.equals("/users", path)
    end)

    it("should extract paths with parameters", function()
      local path = parser:extract_endpoint_path('<Route path="/users/:id"')
      assert.equals("/users/:id", path)
    end)

    it("should handle single quotes", function()
      local path = parser:extract_endpoint_path("<Route path='/users'")
      assert.equals("/users", path)
    end)

    it("should extract from route objects", function()
      local path = parser:extract_endpoint_path('{ path: "/users"')
      assert.equals("/users", path)
    end)

    it("should handle complex parameter patterns", function()
      local path = parser:extract_endpoint_path('<Route path="/users/:userId/posts/:postId"')
      assert.equals("/users/:userId/posts/:postId", path)
    end)
  end)

  describe("HTTP Method Extraction", function()
    it("should extract GET from Route components", function()
      local method = parser:extract_method('<Route path="/users"')
      assert.equals("GET", method)
    end)

    it("should extract GET from route objects", function()
      local method = parser:extract_method('{ path: "/users"')
      assert.equals("GET", method)
    end)

    it("should default to GET for all route patterns", function()
      local method = parser:extract_method('<Route exact path="/users"')
      assert.equals("GET", method)
    end)
  end)

  describe("Base Path Extraction", function()
    it("should handle Router contexts", function()
      local base_path = parser:extract_base_path("App.jsx", 10)
      assert.is_true(base_path == nil or type(base_path) == "string")
    end)
  end)

  describe("Error Handling", function()
    it("should handle malformed routes gracefully", function()
      local result = parser:parse_content("<InvalidComponent>", "test.jsx", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle empty content", function()
      local result = parser:parse_content("", "test.jsx", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle missing file path", function()
      local result = parser:parse_content('<Route path="/users" />', nil, 1, 1)
      assert.is_not_nil(result)
    end)

    it("should return nil for non-React Router content", function()
      local result = parser:parse_content("const users = []", "test.jsx", 1, 1)
      assert.is_nil(result)
    end)
  end)
end)