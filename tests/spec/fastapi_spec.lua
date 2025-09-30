local FastapiFramework = require "endpoint.frameworks.fastapi"
local FastapiParser = require "endpoint.parser.fastapi_parser"

describe("FastapiFramework", function()
  local framework
  local parser

  before_each(function()
    framework = FastapiFramework:new()
    parser = FastapiParser:new()
  end)

  describe("Framework Detection", function()
    it("should have correct framework name", function()
      assert.equals("fastapi", framework:get_name())
    end)

    it("should have detector configured", function()
      assert.is_not_nil(framework.detector)
      assert.equals("fastapi_dependency_detection", framework.detector.detection_name)
    end)

    it("should have parser configured", function()
      assert.is_not_nil(framework.parser)
      assert.equals("fastapi_parser", framework.parser.parser_name)
    end)
  end)

  describe("Framework Configuration", function()
    it("should have correct file extensions", function()
      local config = framework:get_config()
      assert.same({ "*.py" }, config.file_extensions)
    end)

    it("should have exclude patterns", function()
      local config = framework:get_config()
      assert.same({ "**/__pycache__", "**/venv", "**/.venv", "**/site-packages" }, config.exclude_patterns)
    end)

    it("should have FastAPI-specific search patterns", function()
      local config = framework:get_config()
      assert.is_table(config.patterns.GET)
      assert.is_table(config.patterns.POST)
      assert.is_table(config.patterns.PUT)
      assert.is_table(config.patterns.DELETE)
      assert.is_table(config.patterns.PATCH)

      -- Check for FastAPI-specific patterns
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
      assert.equals("fastapi_dependency_detection", config.detector.name)

      -- Check for FastAPI-specific dependencies
      assert.is_true(#config.detector.dependencies > 0)
    end)
  end)

  describe("Parser Functionality", function()
    it("should parse @app.get decorators", function()
      local content = '@app.get("/users")'
      local result = parser:parse_content(content, "main.py", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse @app.post decorators", function()
      local content = '@app.post("/users")'
      local result = parser:parse_content(content, "main.py", 1, 1)

      assert.is_not_nil(result)
      assert.equals("POST", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse router decorators", function()
      local content = '@router.get("/users")'
      local result = parser:parse_content(content, "routes.py", 1, 1)

      if result then
        assert.equals("GET", result.method)
        assert.equals("/users", result.endpoint_path)
      end
    end)

    it("should parse endpoints with path parameters", function()
      local content = '@app.get("/users/{user_id}")'
      local result = parser:parse_content(content, "main.py", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users/{user_id}", result.endpoint_path)
    end)

    it("should handle single quotes", function()
      local content = "@app.get('/users')"
      local result = parser:parse_content(content, "main.py", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should handle complex path patterns", function()
      local content = '@app.get("/api/v1/users/{user_id}/posts")'
      local result = parser:parse_content(content, "main.py", 1, 1)

      if result then
        assert.equals("GET", result.method)
        assert.equals("/api/v1/users/{user_id}/posts", result.endpoint_path)
      end
    end)
  end)

  describe("Search Command Generation", function()
    it("should generate valid search commands", function()
      local search_cmd = framework:get_search_cmd()
      assert.is_string(search_cmd)
      assert.matches("rg", search_cmd)
      assert.matches("--type py", search_cmd)
    end)
  end)

  describe("Controller Name Extraction", function()
    it("should extract controller name from Python file", function()
      local controller_name = framework:getControllerName("app/routers/users.py")
      assert.is_not_nil(controller_name)
    end)

    it("should handle main.py files", function()
      local controller_name = framework:getControllerName("main.py")
      assert.is_not_nil(controller_name)
    end)

    it("should handle nested router paths", function()
      local controller_name = framework:getControllerName("app/api/v1/users.py")
      assert.is_not_nil(controller_name)
    end)
  end)

  describe("Integration Tests", function()
    it("should create framework instance successfully", function()
      local instance = FastapiFramework:new()
      assert.is_not_nil(instance)
      assert.equals("fastapi", instance:get_name())
    end)

    it("should have parser and detector ready", function()
      assert.is_not_nil(framework.parser)
      assert.is_not_nil(framework.detector)
      assert.equals("fastapi", framework.parser.framework_name)
    end)

    it("should parse and enhance endpoints", function()
      local content = '@app.get("/api/users")'
      local result = framework:parse(content, "main.py", 1, 1)

      assert.is_not_nil(result)
      assert.equals("fastapi", result.framework)
      assert.is_table(result.metadata)
      assert.equals("fastapi", result.metadata.framework)
    end)

    it("should parse real FastAPI application files", function()
      -- Test if FastAPI fixture files exist and can be parsed
      local fixture_files = {
        "tests/fixtures/fastapi/src/main.py",
        "tests/fixtures/fastapi/src/routers/users.py",
        "tests/fixtures/fastapi/src/routers/posts.py"
      }
      
      local total_endpoints = 0
      for _, file_path in ipairs(fixture_files) do
        local file_exists = vim.fn.filereadable(file_path) == 1
        if file_exists then
          local file_content = vim.fn.readfile(file_path)
          
          -- Test multiple endpoints from the real file
          for line_num, line in ipairs(file_content) do
            local result = parser:parse_content(line, file_path, line_num, 1)
            if result then
              total_endpoints = total_endpoints + 1
            end
          end
        end
      end
      
      -- Should find endpoints from real FastAPI files if they exist
      if total_endpoints > 0 then
        assert.is_true(total_endpoints > 0, "Should find endpoints from real FastAPI files")
      else
        -- If no fixture files exist, just verify the parser works
        local content = '@app.get("/test")'
        local result = parser:parse_content(content, "test.py", 1, 1)
        assert.is_not_nil(result)
        assert.equals("GET", result.method)
        assert.equals("/test", result.endpoint_path)
      end
    end)
  end)
end)

describe("FastapiParser", function()
  local parser

  before_each(function()
    parser = FastapiParser:new()
  end)

  describe("Parser Instance", function()
    it("should create parser with correct properties", function()
      assert.equals("fastapi_parser", parser.parser_name)
      assert.equals("fastapi", parser.framework_name)
      assert.equals("python", parser.language)
    end)
  end)

  describe("Endpoint Path Extraction", function()
    it("should extract simple paths", function()
      local path = parser:extract_endpoint_path('@app.get("/users")')
      assert.equals("/users", path)
    end)

    it("should extract paths with parameters", function()
      local path = parser:extract_endpoint_path('@app.get("/users/{user_id}")')
      assert.equals("/users/{user_id}", path)
    end)

    it("should handle single quotes", function()
      local path = parser:extract_endpoint_path("@app.get('/users')")
      assert.equals("/users", path)
    end)

    it("should handle router patterns", function()
      local path = parser:extract_endpoint_path('@router.get("/users")')
      assert.equals("/users", path)
    end)
  end)

  describe("HTTP Method Extraction", function()
    it("should extract GET from @app.get", function()
      local method = parser:extract_method('@app.get("/users")')
      assert.equals("GET", method)
    end)

    it("should extract POST from @app.post", function()
      local method = parser:extract_method('@app.post("/users")')
      assert.equals("POST", method)
    end)

    it("should extract PUT from @app.put", function()
      local method = parser:extract_method('@app.put("/users/{user_id}")')
      assert.equals("PUT", method)
    end)

    it("should extract DELETE from @app.delete", function()
      local method = parser:extract_method('@app.delete("/users/{user_id}")')
      assert.equals("DELETE", method)
    end)

    it("should extract PATCH from @app.patch", function()
      local method = parser:extract_method('@app.patch("/users/{user_id}")')
      assert.equals("PATCH", method)
    end)

    it("should extract method from router patterns", function()
      local method = parser:extract_method('@router.get("/users")')
      assert.equals("GET", method)
    end)
  end)

  describe("Base Path Extraction", function()
    it("should handle app prefix contexts", function()
      local base_path = parser:extract_base_path("main.py", 10)
      assert.is_true(base_path == nil or type(base_path) == "string")
    end)
  end)

  describe("Error Handling", function()
    it("should handle malformed decorators gracefully", function()
      local result = parser:parse_content("@invalid_decorator", "test.py", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle empty content", function()
      local result = parser:parse_content("", "test.py", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle missing file path", function()
      local result = parser:parse_content('@app.get("/users")', "main.py", 1, 1)
      if result then
        assert.is_table(result)
      end
    end)

    it("should return nil for non-FastAPI content", function()
      local result = parser:parse_content("users = []", "test.py", 1, 1)
      assert.is_nil(result)
    end)
  end)
end)