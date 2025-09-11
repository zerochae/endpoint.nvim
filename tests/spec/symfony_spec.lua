describe(" Symfony framework", function()
  local symfony = require "endpoint.framework.registry.symfony"

  describe("pattern matching", function()
    it("should detect GET routes with #[Route] attributes", function()
      local patterns = symfony:get_patterns "get"
      assert.is_not_nil(patterns)
      assert.is_true(#patterns > 0)
    end)

    it("should detect POST routes", function()
      local patterns = symfony:get_patterns "post"
      assert.is_not_nil(patterns)
      assert.is_true(#patterns > 0)
    end)

    it("should return empty for unknown methods", function()
      local patterns = symfony:get_patterns "unknown"
      assert.are.same({}, patterns)
    end)
  end)

  describe("file type detection", function()
    it("should return php file types", function()
      local file_types = symfony:get_file_types()
      assert.is_true(vim.tbl_contains(file_types, "php"))
    end)
  end)

  describe("path extraction with real files", function()
    it("should extract path from UserController edit method", function()
      local real_file = "tests/fixtures/symfony/src/Controller/UserController.php"
      local endpoint_path = symfony:_extract_method_mapping(real_file, 12)  -- #[Route('/edit'...
      assert.are.equal("/edit", endpoint_path)
    end)

    it("should extract path from UserController change-password method", function()
      local real_file = "tests/fixtures/symfony/src/Controller/UserController.php"
      local endpoint_path = symfony:_extract_method_mapping(real_file, 18)  -- #[Route('/change-password'...
      assert.are.equal("/change-password", endpoint_path)
    end)
  end)

  describe("base path extraction with real files", function()
    it("should extract profile base path from real UserController", function()
      local real_file = "tests/fixtures/symfony/src/Controller/UserController.php"
      local base_path = symfony:get_base_path(real_file, 12)
      assert.are.equal("/profile", base_path)
    end)
  end)

  describe("ripgrep command generation", function()
    it("should generate valid ripgrep command", function()
      local cmd = symfony:get_grep_cmd("get", {})
      assert.is_string(cmd)
      assert.is_not_nil(cmd:match("rg"))
    end)

    it("should include exclude patterns", function()
      local cmd = symfony:get_grep_cmd("get", {})
      assert.is_not_nil(cmd:match("vendor"))
      assert.is_not_nil(cmd:match("var"))
    end)
  end)

  describe("line parsing with real files", function()
    it("should parse UserController edit route correctly", function()
      local real_file = "tests/fixtures/symfony/src/Controller/UserController.php"
      local line = real_file .. ":12:5:#[Route('/edit'"
      local result = symfony:parse_line(line, "GET", {})

      assert.is_not_nil(result)
      assert.are.equal(real_file, result.file_path)
      assert.are.equal(12, result.line_number)
      assert.are.equal("/profile/edit", result.endpoint_path)
      assert.are.equal("GET", result.method)
    end)
  end)
end)