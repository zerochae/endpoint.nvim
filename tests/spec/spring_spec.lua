describe(" Spring framework", function()
  local spring = require "endpoint.framework.registry.spring"

  describe("pattern matching", function()
    it("should detect GET routes with @GetMapping", function()
      local patterns = spring:get_patterns "get"
      assert.is_not_nil(patterns)
      assert.is_true(#patterns > 0)
      assert.is_true(vim.tbl_contains(patterns, "@GetMapping"))
    end)

    it("should detect POST routes with @PostMapping", function()
      local patterns = spring:get_patterns "post"
      assert.is_not_nil(patterns)
      assert.is_true(#patterns > 0)
      assert.is_true(vim.tbl_contains(patterns, "@PostMapping"))
    end)

    it("should return empty for unknown methods", function()
      local patterns = spring:get_patterns "unknown"
      assert.are.same({}, patterns)
    end)
  end)

  describe("file type detection", function()
    it("should return java file types", function()
      local file_types = spring:get_file_types()
      assert.is_true(vim.tbl_contains(file_types, "java"))
    end)
  end)

  describe("path extraction with real files", function()
    it("should extract path from @GetMapping in UserController", function()
      local real_file = "tests/fixtures/spring/src/main/java/com/example/UserController.java"
      local endpoint_path = spring:_extract_method_mapping(real_file, 9)  -- @GetMapping("/list")
      assert.are.equal("/list", endpoint_path)
    end)

    it("should extract path with parameter from @GetMapping", function()
      local real_file = "tests/fixtures/spring/src/main/java/com/example/UserController.java"
      local endpoint_path = spring:_extract_method_mapping(real_file, 14)  -- @GetMapping("/{id}")
      assert.are.equal("/{id}", endpoint_path)
    end)
  end)

  describe("base path extraction with real files", function()
    it("should extract base path from UserController @RequestMapping", function()
      local real_file = "tests/fixtures/spring/src/main/java/com/example/UserController.java"
      local base_path = spring:get_base_path(real_file, 8)
      assert.are.equal("/users", base_path)
    end)
  end)

  describe("ripgrep command generation", function()
    it("should generate valid ripgrep command", function()
      local cmd = spring:get_grep_cmd("get", {})
      assert.is_string(cmd)
      assert.is_not_nil(cmd:match("rg"))
    end)

    it("should include exclude patterns", function()
      local cmd = spring:get_grep_cmd("get", {})
      assert.is_not_nil(cmd:match("target"))
      assert.is_not_nil(cmd:match("build"))
    end)
  end)

  describe("line parsing with real files", function()
    it("should parse UserController GET mapping", function()
      local real_file = "tests/fixtures/spring/src/main/java/com/example/UserController.java"
      local line = real_file .. ":9:5:@GetMapping(\"/list\")"
      local result = spring:parse_line(line, "GET", {})

      assert.is_not_nil(result)
      assert.are.equal(real_file, result.file_path)
      assert.are.equal(9, result.line_number)
      assert.are.equal("/users/list", result.endpoint_path)
      assert.are.equal("GET", result.method)
    end)

    it("should parse TestController @GetMapping without parameters correctly", function()
      local real_file = "tests/fixtures/spring/src/main/java/com/example/TestController.java"
      local line = real_file .. ":14:5:    @GetMapping"
      local result = spring:parse_line(line, "GET", {})

      assert.is_not_nil(result)
      assert.are.equal(real_file, result.file_path)
      assert.are.equal(14, result.line_number)
      assert.are.equal("/api/v1/{userId}/orders", result.endpoint_path)
      assert.are.equal("GET", result.method)
    end)

    it("should parse TestController @GetMapping with path correctly", function()
      local real_file = "tests/fixtures/spring/src/main/java/com/example/TestController.java"
      local line = real_file .. ":24:5:    @GetMapping(\"/status\")"
      local result = spring:parse_line(line, "GET", {})

      assert.is_not_nil(result)
      assert.are.equal(real_file, result.file_path)
      assert.are.equal(24, result.line_number)
      assert.are.equal("/api/v1/{userId}/orders/status", result.endpoint_path)
      assert.are.equal("GET", result.method)
    end)
  end)

  describe("PathVariable extraction bug fix", function()
    it("should not extract path from @PathVariable when @GetMapping has no parentheses", function()
      local real_file = "tests/fixtures/spring/src/main/java/com/example/TestController.java"
      local method_path = spring:_extract_method_mapping(real_file, 14)  -- @GetMapping without ()
      assert.are.equal("", method_path)  -- Should be empty, not "userId"
    end)

    it("should extract correct base path from TestController", function()
      local real_file = "tests/fixtures/spring/src/main/java/com/example/TestController.java"
      local base_path = spring:get_base_path(real_file, 14)
      assert.are.equal("/api/v1/{userId}/orders", base_path)
    end)
  end)
end)