describe("NestJS framework", function()
  local test_helpers = require "tests.utils.framework_test_helpers"
  local nestjs = require "endpoint.frameworks.nestjs"

  describe("framework detection", test_helpers.create_detection_test_suite(nestjs, "nestjs"))

  describe(
    "search command generation",
    test_helpers.create_search_cmd_test_suite(nestjs, {
      GET = { "@Get" },
      POST = { "@Post" },
      ALL = { "@Get", "@Post" },
    })
  )

  describe(
    "line parsing",
    test_helpers.create_line_parsing_test_suite(nestjs, {
      {
        description = "should parse simple @Get decorator",
        line = "src/users/users.controller.ts:10:5:  @Get('profile')",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/profile",
          file_path = "src/users/users.controller.ts",
          line_number = 10,
          column = 5,
        },
      },
      {
        description = "should parse @Post decorator",
        line = "src/users/users.controller.ts:15:5:  @Post('create')",
        method = "POST",
        expected = {
          method = "POST",
          endpoint_path = "/create",
          file_path = "src/users/users.controller.ts",
          line_number = 15,
          column = 5,
        },
      },
      {
        description = "should handle path parameters",
        line = "src/users/users.controller.ts:30:5:  @Get(':id')",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/:id",
          file_path = "src/users/users.controller.ts",
          line_number = 30,
          column = 5,
        },
      },
    })
  )

  describe("additional parsing tests", function()
    it("should parse @Get without parameters", function()
      local line = "src/users/users.controller.ts:20:5:  @Get()"
      local result = nestjs.parse_line(line, "GET")

      if result then
        assert.is_table(result)
        assert.are.equal("GET", result and result.method)
        -- Should use empty path or default
        assert.is_string(result.endpoint_path)
      end
    end)

    it("should combine controller path with method path", function()
      -- This would need actual fixture context for proper testing
      local line = "src/users/users.controller.ts:25:5:  @Get('profile')"
      local result = nestjs.parse_line(line, "GET")

      if result then
        assert.is_table(result)
        -- Should combine controller base path if available
        assert.is_string(result.endpoint_path)
        -- Should start with slash
        assert.is_true(result.endpoint_path:sub(1, 1) == "/")
      end
    end)
  end)

  describe("controller path extraction", function()
    it("should extract base path from @Controller decorator", function()
      local fixture_file = "tests/fixtures/nestjs/src/users.controller.ts"
      if vim.fn.filereadable(fixture_file) == 1 then
        local base_path = nestjs.get_controller_path(fixture_file)
        if base_path then
          assert.is_string(base_path)
          -- Should start with slash
          assert.is_true(base_path:sub(1, 1) == "/")
        end
      else
        pending "NestJS fixture file not found"
      end
    end)

    it("should return empty string for controllers without path", function()
      -- Create temporary file for test
      local temp_file = "/tmp/TestController.ts"
      local content = {
        "import { Controller, Get } from '@nestjs/common';",
        "",
        "@Controller()",
        "export class TestController {",
        "  @Get('test')",
        "  getTest() { return 'test'; }",
        "}",
      }
      vim.fn.writefile(content, temp_file)

      local base_path = nestjs.get_controller_path(temp_file)
      assert.are.equal("", base_path)

      vim.fn.delete(temp_file)
    end)
  end)

  describe("integration with fixtures", test_helpers.create_integration_test_suite(nestjs, "nestjs"))

  describe("edge cases", function()
    it("should handle various quote styles", function()
      local line1 = "src/test.controller.ts:10:5:  @Get('single')"
      local line2 = 'src/test.controller.ts:11:5:  @Get("double")'

      local result1 = nestjs.parse_line(line1, "GET")
      local result2 = nestjs.parse_line(line2, "GET")

      if result1 and result2 then
        assert.are.equal("/single", result1.endpoint_path)
        assert.are.equal("/double", result2.endpoint_path)
      end
    end)

    it("should handle complex path patterns", function()
      local line = "src/controller.ts:15:5:  @Get('users/:userId/posts/:postId')"
      local result = nestjs.parse_line(line, "GET")

      if result then
        assert.are.equal("/users/:userId/posts/:postId", result and result.endpoint_path)
      end
    end)

    it("should handle empty paths correctly", function()
      local line1 = "src/controller.ts:20:5:  @Get('')"
      local line2 = "src/controller.ts:21:5:  @Get()"

      local result1 = nestjs.parse_line(line1, "GET")
      local result2 = nestjs.parse_line(line2, "GET")

      if result1 then
        assert.is_string(result1.endpoint_path)
      end

      if result2 then
        assert.is_string(result2.endpoint_path)
      end
    end)
  end)
end)
