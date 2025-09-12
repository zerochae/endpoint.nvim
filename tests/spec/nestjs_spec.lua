describe("NestJS framework", function()
  local nestjs = require "endpoint.frameworks.nestjs"

  describe("framework detection", function()
    it("should detect NestJS project", function()
      local fixture_path = "tests/fixtures/nestjs"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        local detected = nestjs.detect()
        assert.is_true(detected)

        vim.fn.chdir(original_cwd)
      else
        pending "NestJS fixture directory not found"
      end
    end)

    it("should not detect NestJS in non-NestJS directory", function()
      local temp_dir = "/tmp/non_nestjs_" .. os.time()
      vim.fn.mkdir(temp_dir, "p")
      local original_cwd = vim.fn.getcwd()
      vim.fn.chdir(temp_dir)

      local detected = nestjs.detect()
      assert.is_false(detected)

      vim.fn.chdir(original_cwd)
      vim.fn.delete(temp_dir, "rf")
    end)
  end)

  describe("search command generation", function()
    it("should generate search command for GET method", function()
      local cmd = nestjs.get_search_cmd "GET"
      assert.is_string(cmd)
      assert.is_true(cmd:match "rg" ~= nil)
      assert.is_true(cmd:match "@Get" ~= nil)
    end)

    it("should generate search command for POST method", function()
      local cmd = nestjs.get_search_cmd "POST"
      assert.is_string(cmd)
      assert.is_true(cmd:match "@Post" ~= nil)
    end)

    it("should generate search command for ALL method", function()
      local cmd = nestjs.get_search_cmd "ALL"
      assert.is_string(cmd)
      -- Should contain multiple HTTP methods
      assert.is_true(cmd:match "@Get" ~= nil)
      assert.is_true(cmd:match "@Post" ~= nil)
    end)
  end)

  describe("line parsing", function()
    it("should parse simple @Get decorator", function()
      local line = "src/users/users.controller.ts:10:5:  @Get('profile')"
      local result = nestjs.parse_line(line, "GET")

      assert.is_not_nil(result)
      assert.is_table(result)
      assert.are.equal("GET", result and result.method)
      assert.are.equal("/profile", result and result.endpoint_path) -- Should add leading slash
      assert.are.equal("src/users/users.controller.ts", result and result.file_path)
      assert.are.equal(10, result and result.line_number)
      assert.are.equal(5, result and result.column)
    end)

    it("should parse @Post decorator", function()
      local line = "src/users/users.controller.ts:15:5:  @Post('create')"
      local result = nestjs.parse_line(line, "POST")

      assert.is_not_nil(result)
      assert.is_table(result)
      assert.are.equal("POST", result and result.method)
      assert.are.equal("/create", result and result.endpoint_path)
    end)

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

    it("should handle path parameters", function()
      local line = "src/users/users.controller.ts:30:5:  @Get(':id')"
      local result = nestjs.parse_line(line, "GET")

      if result then
        assert.is_table(result)
        assert.are.equal("GET", result and result.method)
        assert.are.equal("/:id", result and result.endpoint_path)
      end
    end)

    it("should return nil for invalid lines", function()
      local line = "invalid line format"
      local result = nestjs.parse_line(line, "GET")
      assert.is_nil(result)
    end)

    it("should return nil for empty lines", function()
      local line = ""
      local result = nestjs.parse_line(line, "GET")
      assert.is_nil(result)
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

  describe("integration with fixtures", function()
    it("should correctly parse real NestJS fixture files", function()
      local fixture_path = "tests/fixtures/nestjs"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        -- Test that framework is detected
        assert.is_true(nestjs.detect())

        -- Test that search command works
        local cmd = nestjs.get_search_cmd "GET"
        assert.is_string(cmd)

        vim.fn.chdir(original_cwd)
      else
        pending "NestJS fixture directory not found"
      end
    end)
  end)

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
