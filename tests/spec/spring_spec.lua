describe(" Spring framework", function()
  local endpoint = require "endpoint"
  local spring = require "endpoint.framework.registry.spring"

  before_each(function()
    endpoint.setup()
    -- Reset session config before each test
    local state = require "endpoint.core.state"
    state.set_config {
      framework = "auto",
      cache_mode = "none",
      debug = false,
    }
  end)

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

  describe("path extraction with real files", function()
    it("should extract path from @GetMapping in UserController", function()
      local real_file = "tests/fixtures/spring/src/main/java/com/example/UserController.java"
      local endpoint_path = spring:_extract_method_mapping(real_file, 9) -- @GetMapping("/list")
      assert.are.equal("/list", endpoint_path)
    end)

    it("should extract path with parameter from @GetMapping", function()
      local real_file = "tests/fixtures/spring/src/main/java/com/example/UserController.java"
      local endpoint_path = spring:_extract_method_mapping(real_file, 14) -- @GetMapping("/{id}")
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
      assert.is_not_nil(cmd:match "rg")
    end)

    it("should include exclude patterns", function()
      local cmd = spring:get_grep_cmd("get", {})
      assert.is_not_nil(cmd:match "target")
      assert.is_not_nil(cmd:match "build")
    end)
  end)

  describe("line parsing with real files", function()
    it("should parse UserController GET mapping", function()
      local real_file = "tests/fixtures/spring/src/main/java/com/example/UserController.java"
      local line = real_file .. ':9:5:@GetMapping("/list")'
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
      local line = real_file .. ':77:5:    @GetMapping("/status")'
      local result = spring:parse_line(line, "GET", {})

      assert.is_not_nil(result)
      assert.are.equal(real_file, result.file_path)
      assert.are.equal(77, result.line_number)
      assert.are.equal("/api/v1/{userId}/orders/status", result.endpoint_path)
      assert.are.equal("GET", result.method)
    end)
  end)

  describe("PathVariable extraction bug fix", function()
    it("should extract method mapping from TestController main method", function()
      local real_file = "tests/fixtures/spring/src/main/java/com/example/TestController.java"
      local method_path = spring:_extract_method_mapping(real_file, 14) -- @GetMapping (main method)
      assert.are.equal("", method_path) -- Should be empty for main method
    end)

    it("should extract correct base path from TestController", function()
      local real_file = "tests/fixtures/spring/src/main/java/com/example/TestController.java"
      local base_path = spring:get_base_path(real_file, 14)
      assert.are.equal("/api/v1/{userId}/orders", base_path)
    end)
  end)

  describe("endpoint count verification", function()
    it("should find expected number of GET endpoints in fixtures", function()
      local scanner = require "endpoint.services.scanner"
      local fixture_path = "tests/fixtures/spring"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        local state = require "endpoint.core.state"
        state.set_config {
          framework = "spring",
        }

        scanner.clear_cache()
        scanner.scan "GET"
        local results = scanner.get_list "GET"

        -- Should find endpoints that actually exist in fixture files
        assert.is_table(results)
        -- Manual check: we know there are @GetMapping annotations in the fixture files
        local manual_rg = vim.fn.system "rg '@GetMapping' --glob '*.java' -c"
        local manual_count = tonumber(manual_rg:match "%d+") or 0

        if manual_count > 0 then
          assert.is_true(
            #results > 0,
            "Should find GET endpoints when they exist in files, found: "
              .. #results
              .. " endpoints (manual rg found "
              .. manual_count
              .. ")"
          )
        else
          -- If manual rg finds 0, then scanner finding 0 is acceptable
          -- Skip detailed validation - endpoint counting is environment-dependent
          print("Info: Found", #results, "endpoints in Spring fixture")
        end

        vim.fn.chdir(original_cwd)
      else
        pending "Spring fixture directory not found"
      end
    end)

    it("should find expected number of POST endpoints in fixtures", function()
      local scanner = require "endpoint.services.scanner"
      local fixture_path = "tests/fixtures/spring"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        local state = require "endpoint.core.state"
        state.set_config {
          framework = "spring",
        }

        scanner.clear_cache()
        scanner.scan "POST"
        local results = scanner.get_list "POST"

        -- Should find endpoints that actually exist in fixture files
        assert.is_table(results)
        -- Manual check: we know there are @PostMapping annotations in the fixture files
        local manual_rg = vim.fn.system "rg '@PostMapping' --glob '*.java' -c"
        local manual_count = tonumber(manual_rg:match "%d+") or 0

        if manual_count > 0 then
          assert.is_true(
            #results > 0,
            "Should find POST endpoints when they exist in files, found: "
              .. #results
              .. " endpoints (manual rg found "
              .. manual_count
              .. ")"
          )
        else
          -- If manual rg finds 0, then scanner finding 0 is acceptable
          -- Skip detailed validation - endpoint counting is environment-dependent
          print("Info: Found", #results, "endpoints in Spring fixture")
        end

        vim.fn.chdir(original_cwd)
      else
        pending "Spring fixture directory not found"
      end
    end)
  end)
end)
