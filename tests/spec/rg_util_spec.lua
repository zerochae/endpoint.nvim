local rg_util = require "endpoint.utils.rg"

describe("Ripgrep Utility", function()
  describe("parse_result_line", function()
    it("should parse Unix path correctly", function()
      local line = "/home/user/project/src/Controller.java:10:5:@GetMapping"
      local result = rg_util.parse_result_line(line)

      assert.is_not_nil(result)
      assert.equals("/home/user/project/src/Controller.java", result.file_path)
      assert.equals(10, result.line_number)
      assert.equals(5, result.column)
      assert.equals("@GetMapping", result.content)
    end)

    it("should parse Windows path correctly", function()
      local line = "C:\\Users\\user\\project\\src\\Controller.java:10:5:@GetMapping"
      local result = rg_util.parse_result_line(line)

      assert.is_not_nil(result)
      assert.equals("C:\\Users\\user\\project\\src\\Controller.java", result.file_path)
      assert.equals(10, result.line_number)
      assert.equals(5, result.column)
      assert.equals("@GetMapping", result.content)
    end)

    it("should parse Windows path with forward slashes", function()
      local line = "C:/Users/user/project/src/Controller.java:10:5:@GetMapping"
      local result = rg_util.parse_result_line(line)

      assert.is_not_nil(result)
      assert.equals("C:/Users/user/project/src/Controller.java", result.file_path)
      assert.equals(10, result.line_number)
      assert.equals(5, result.column)
      assert.equals("@GetMapping", result.content)
    end)

    it("should handle content with colons", function()
      local line = "/path/to/file.ts:15:8:@Query(() => User, { name: 'user' })"
      local result = rg_util.parse_result_line(line)

      assert.is_not_nil(result)
      assert.equals("/path/to/file.ts", result.file_path)
      assert.equals(15, result.line_number)
      assert.equals(8, result.column)
      assert.equals("@Query(() => User, { name: 'user' })", result.content)
    end)

    it("should handle Windows path with content containing colons", function()
      local line = "D:\\project\\app\\resolver.ts:20:10:@Mutation(() => User, { description: 'test' })"
      local result = rg_util.parse_result_line(line)

      assert.is_not_nil(result)
      assert.equals("D:\\project\\app\\resolver.ts", result.file_path)
      assert.equals(20, result.line_number)
      assert.equals(10, result.column)
      assert.equals("@Mutation(() => User, { description: 'test' })", result.content)
    end)

    it("should return nil for empty line", function()
      local result = rg_util.parse_result_line("")
      assert.is_nil(result)
    end)

    it("should return nil for nil input", function()
      local result = rg_util.parse_result_line(nil)
      assert.is_nil(result)
    end)

    it("should return nil for malformed line", function()
      local result = rg_util.parse_result_line("invalid line format")
      assert.is_nil(result)
    end)

    it("should handle relative paths", function()
      local line = "src/controllers/user.controller.ts:25:3:@Get('/users')"
      local result = rg_util.parse_result_line(line)

      assert.is_not_nil(result)
      assert.equals("src/controllers/user.controller.ts", result.file_path)
      assert.equals(25, result.line_number)
      assert.equals(3, result.column)
      assert.equals("@Get('/users')", result.content)
    end)
  end)
end)
