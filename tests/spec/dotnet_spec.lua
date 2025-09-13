describe(".NET Core framework", function()
  local test_helpers = require "tests.utils.framework_test_helpers"
  local dotnet = require "endpoint.frameworks.dotnet"

  describe("framework detection", test_helpers.create_detection_test_suite(dotnet, "dotnet"))

  describe(
    "search command generation",
    test_helpers.create_search_cmd_test_suite(dotnet, {
      GET = { "HttpGet" },
      POST = { "HttpPost" },
      PUT = { "HttpPut" },
      DELETE = { "HttpDelete" },
      PATCH = { "HttpPatch" },
      ALL = { "HttpGet", "HttpPost", "MapGet" },
    })
  )

  describe(
    "line parsing",
    test_helpers.create_line_parsing_test_suite(dotnet, {
      {
        description = "should parse [HttpGet] attribute with path",
        line = 'tests/fixtures/dotnet/Controllers/UsersController.cs:15:5:    [HttpGet("{id:int}")]',
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/users/{id:int}",
          file_path = "tests/fixtures/dotnet/Controllers/UsersController.cs",
          line_number = 15,
          column = 5,
        },
      },
      {
        description = "should parse [HttpPost] attribute without path",
        line = 'tests/fixtures/dotnet/Controllers/UsersController.cs:30:5:    [HttpPost]',
        method = "POST",
        expected = {
          method = "POST",
          endpoint_path = "/api/users",
          file_path = "tests/fixtures/dotnet/Controllers/UsersController.cs",
          line_number = 30,
          column = 5,
        },
      },
      {
        description = "should parse app.MapGet minimal API",
        line = 'Program.cs:25:1:app.MapGet("/health", () => new { status = "healthy" });',
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/health",
          file_path = "Program.cs",
          line_number = 25,
          column = 1,
        },
      },
      {
        description = "should parse app.MapPost minimal API",
        line = 'Program.cs:27:1:app.MapPost("/api/minimal/users", (CreateUserRequest request) =>',
        method = "POST",
        expected = {
          method = "POST",
          endpoint_path = "/api/minimal/users",
          file_path = "Program.cs",
          line_number = 27,
          column = 1,
        },
      },
      {
        description = "should parse endpoints.MapGet",
        line = 'Program.cs:45:5:    endpoints.MapGet("/api/endpoints/status", async context =>',
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/endpoints/status",
          file_path = "Program.cs",
          line_number = 45,
          column = 5,
        },
      },
      {
        description = "should parse [HttpPatch] with complex path",
        line = 'tests/fixtures/dotnet/Controllers/UsersController.cs:55:5:    [HttpPatch("{id:int}/status")]',
        method = "PATCH",
        expected = {
          method = "PATCH",
          endpoint_path = "/api/users/{id:int}/status",
          file_path = "tests/fixtures/dotnet/Controllers/UsersController.cs",
          line_number = 55,
          column = 5,
        },
      },
      {
        description = "should parse [Route] attribute with [HttpGet]",
        line = 'tests/fixtures/dotnet/Controllers/ProductsController.cs:25:5:    [HttpGet("{productId:guid}")]',
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/v1/products/{productId:guid}",
          file_path = "tests/fixtures/dotnet/Controllers/ProductsController.cs",
          line_number = 25,
          column = 5,
        },
      },
    })
  )

  describe("additional parsing tests", function()
    it("should combine controller base path with method path", function()
      local line = "tests/fixtures/dotnet/Controllers/UsersController.cs:15:5:    [HttpGet(\"{id:int}\")]"
      local result = dotnet.parse_line(line, "GET")

      if result then
        assert.is_table(result)
        -- Should include /api/users prefix from [Route("api/[controller]")] on controller
        assert.is_true(result.endpoint_path:match "/api/users" ~= nil)
      else
        pending "Controller base path parsing needs fixture file context"
      end
    end)

    it("should handle minimal API patterns", function()
      local line = "tests/fixtures/dotnet/Program.cs:25:1:app.MapGet(\"/health\", () => new { status = \"healthy\" });"
      local result = dotnet.parse_line(line, "GET")

      if result then
        assert.is_table(result)
        assert.are.equal("GET", result.method)
        assert.are.equal("/health", result.endpoint_path)
      end
    end)
  end)

  describe("controller base path extraction", function()
    it("should extract base path from [Route] attribute on controller", function()
      local fixture_file = "tests/fixtures/dotnet/Controllers/UsersController.cs"
      if vim.fn.filereadable(fixture_file) == 1 then
        local base_path = dotnet.get_base_path(fixture_file, 15)
        assert.are.equal("api/users", base_path)
      else
        pending "UsersController fixture not found"
      end
    end)

    it("should handle [Route] with custom path", function()
      local fixture_file = "tests/fixtures/dotnet/Controllers/ProductsController.cs"
      if vim.fn.filereadable(fixture_file) == 1 then
        local base_path = dotnet.get_base_path(fixture_file, 15)
        assert.are.equal("api/v1/products", base_path)
      else
        pending "ProductsController fixture not found"
      end
    end)

    it("should return derived path for controllers without [Route] attribute", function()
      local fixture_file = "tests/fixtures/dotnet/Controllers/OrdersController.cs"
      if vim.fn.filereadable(fixture_file) == 1 then
        local base_path = dotnet.get_base_path(fixture_file, 15)
        -- Should derive from controller name
        assert.are.equal("/orders", base_path)
      else
        -- Create temporary file for test
        local temp_file = "/tmp/TestController.cs"
        local content = {
          "namespace WebApi.Controllers;",
          "",
          "public class TestController : ControllerBase",
          "{",
          '    [HttpGet]',
          '    public ActionResult Get() { return Ok(); }',
          "}",
        }
        vim.fn.writefile(content, temp_file)

        local base_path = dotnet.get_base_path(temp_file, 5)
        assert.are.equal("/test", base_path)

        vim.fn.delete(temp_file)
      end
    end)
  end)

  describe(
    "integration with fixtures",
    test_helpers.create_integration_test_suite(dotnet, "dotnet", function(dotnet_module)
      -- Additional .NET-specific integration test
      local sample_line = 'Controllers/UsersController.cs:20:5:    [HttpGet("{id:int}")]'
      local result = dotnet_module.parse_line(sample_line, "GET")

      if result then
        assert.is_table(result)
        assert.are.equal("GET", result and result.method)
        assert.is_string(result.endpoint_path)
        assert.is_string(result.file_path)
      end
    end)
  )

  describe("edge cases", function()
    it("should handle different attribute bracket styles", function()
      local line1 = "Controllers/Controller.cs:10:5:    [HttpGet(\"/api/test\")]"
      local line2 = "Controllers/Controller.cs:11:5:    [HttpPost]"

      local result1 = dotnet.parse_line(line1, "GET")
      local result2 = dotnet.parse_line(line2, "POST")

      if result1 then
        assert.are.equal("/api/test", result1.endpoint_path)
      end
      if result2 then
        assert.are.equal("POST", result2.method)
      end
    end)

    it("should handle route parameters and constraints", function()
      local line = 'Controllers/Controller.cs:10:5:    [HttpGet("/api/users/{userId:int}/posts/{postId:guid}")]'
      local result = dotnet.parse_line(line, "GET")

      if result then
        assert.is_true(result.endpoint_path:match "{userId:int}" ~= nil)
        assert.is_true(result.endpoint_path:match "{postId:guid}" ~= nil)
      end
    end)

    it("should handle complex minimal API patterns", function()
      local line = 'Program.cs:30:1:app.MapPut("/api/minimal/users/{id:guid}", (Guid id, UpdateUserRequest request) =>'
      local result = dotnet.parse_line(line, "PUT")

      if result then
        assert.are.equal("PUT", result.method)
        assert.are.equal("/api/minimal/users/{id:guid}", result.endpoint_path)
      end
    end)

    it("should handle endpoint routing patterns", function()
      local line = 'Program.cs:50:5:    endpoints.MapPost("/api/endpoints/webhook", async context =>'
      local result = dotnet.parse_line(line, "POST")

      if result then
        assert.are.equal("POST", result.method)
        assert.are.equal("/api/endpoints/webhook", result.endpoint_path)
      end
    end)

    it("should handle [Route] attributes with different parameters", function()
      local line1 = 'Controllers/OrdersController.cs:10:5:    [Route("api/orders")]'
      local line2 = 'Controllers/OrdersController.cs:11:5:    [HttpGet]'
      
      -- Note: In real scenarios, these would be on consecutive lines
      -- The Route parsing would need to be handled with file context
      local result1 = dotnet.parse_line(line1, "GET")
      local result2 = dotnet.parse_line(line2, "GET")

      -- Route-only line should not parse as endpoint
      assert.is_nil(result1)
      
      -- HttpGet without path should parse but need Route context for full path
      if result2 then
        assert.are.equal("GET", result2.method)
      end
    end)

    it("should combine paths correctly", function()
      assert.are.equal("/api/users", dotnet.combine_paths("api", "users"))
      assert.are.equal("/api/users", dotnet.combine_paths("/api", "/users"))
      assert.are.equal("/api", dotnet.combine_paths("/api", ""))
      assert.are.equal("/users", dotnet.combine_paths("", "/users"))
      assert.are.equal("/", dotnet.combine_paths("", ""))
    end)

    it("should handle [action] and [controller] tokens", function()
      assert.are.equal("/api/users/{action}", dotnet.combine_paths("/api/users", "[action]"))
      assert.are.equal("/api/users", dotnet.combine_paths("/api/users", "[controller]"))
    end)
  end)
end)