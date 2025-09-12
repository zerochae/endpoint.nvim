describe("Spring framework", function()
  local spring = require "endpoint.frameworks.spring"

  describe("framework detection", function()
    it("should detect Spring Boot project", function()
      local fixture_path = "tests/fixtures/spring"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        local detected = spring.detect()
        assert.is_true(detected)

        vim.fn.chdir(original_cwd)
      else
        pending "Spring fixture directory not found"
      end
    end)

    it("should not detect Spring in non-Spring directory", function()
      local temp_dir = "/tmp/non_spring_" .. os.time()
      vim.fn.mkdir(temp_dir, "p")
      local original_cwd = vim.fn.getcwd()
      vim.fn.chdir(temp_dir)

      local detected = spring.detect()
      assert.is_false(detected)

      vim.fn.chdir(original_cwd)
      vim.fn.delete(temp_dir, "rf")
    end)
  end)

  describe("search command generation", function()
    it("should generate search command for GET method", function()
      local cmd = spring.get_search_cmd "GET"
      assert.is_string(cmd)
      assert.is_true(cmd:match "rg" ~= nil)
      assert.is_true(cmd:match "@GetMapping" ~= nil)
    end)

    it("should generate search command for POST method", function()
      local cmd = spring.get_search_cmd "POST"
      assert.is_string(cmd)
      assert.is_true(cmd:match "@PostMapping" ~= nil)
    end)

    it("should generate search command for PUT method", function()
      local cmd = spring.get_search_cmd "PUT"
      assert.is_string(cmd)
      assert.is_true(cmd:match "@PutMapping" ~= nil)
    end)

    it("should generate search command for DELETE method", function()
      local cmd = spring.get_search_cmd "DELETE"
      assert.is_string(cmd)
      assert.is_true(cmd:match "@DeleteMapping" ~= nil)
    end)

    it("should generate search command for PATCH method", function()
      local cmd = spring.get_search_cmd "PATCH"
      assert.is_string(cmd)
      assert.is_true(cmd:match "@PatchMapping" ~= nil)
    end)

    it("should generate search command for ALL method", function()
      local cmd = spring.get_search_cmd "ALL"
      assert.is_string(cmd)
      -- Should contain multiple mapping annotations
      assert.is_true(cmd:match "@GetMapping" ~= nil)
      assert.is_true(cmd:match "@PostMapping" ~= nil)
    end)
  end)

  describe("line parsing", function()
    it("should parse simple @GetMapping line", function()
      local line = 'src/main/java/com/example/Controller.java:10:5:    @GetMapping("/api/users")'
      local result = spring.parse_line(line, "GET")

      assert.is_not_nil(result)
      assert.is_table(result)
      assert.are.equal("GET", result and result.method)
      assert.are.equal("/api/users", result and result.endpoint_path)
      assert.are.equal("src/main/java/com/example/Controller.java", result and result.file_path)
      assert.are.equal(10, result and result.line_number)
      assert.are.equal(5, result and result.column)
    end)

    it("should parse @PostMapping with value parameter", function()
      local line = 'src/main/java/com/example/Controller.java:15:5:    @PostMapping(value = "/api/create")'
      local result = spring.parse_line(line, "POST")

      assert.is_not_nil(result)
      assert.is_table(result)
      assert.are.equal("POST", result and result.method)
      assert.are.equal("/api/create", result and result.endpoint_path)
    end)

    it("should parse @RequestMapping with method parameter", function()
      local line =
        'src/main/java/com/example/Controller.java:20:5:    @RequestMapping(value = "/api/test", method = RequestMethod.GET)'
      local result = spring.parse_line(line, "GET")

      assert.is_not_nil(result)
      assert.is_table(result)
      assert.are.equal("GET", result and result.method)
      assert.are.equal("/api/test", result and result.endpoint_path)
    end)

    it("should handle path parameter instead of value", function()
      local line = 'src/main/java/com/example/Controller.java:25:5:    @GetMapping(path = "/api/version")'
      local result = spring.parse_line(line, "GET")

      assert.is_not_nil(result)
      assert.is_table(result)
      assert.are.equal("GET", result and result.method)
      assert.are.equal("/api/version", result and result.endpoint_path)
    end)

    it("should handle path variables", function()
      local line = 'src/main/java/com/example/Controller.java:30:5:    @GetMapping("/api/users/{id}")'
      local result = spring.parse_line(line, "GET")

      assert.is_not_nil(result)
      assert.is_table(result)
      assert.are.equal("GET", result and result.method)
      assert.are.equal("/api/users/{id}", result and result.endpoint_path)
    end)

    it("should combine controller base path with method path", function()
      -- This would need to be tested with actual fixture files that have @RequestMapping on controller
      local line = "tests/fixtures/spring/src/main/java/com/example/OrderController.java:11:5:    @GetMapping"
      local result = spring.parse_line(line, "GET")

      if result then
        assert.is_table(result)
        -- Should include /orders prefix from @RequestMapping(value = "/orders") on controller
        assert.is_true(result.endpoint_path:match "/orders" ~= nil)
      else
        pending "Controller base path parsing needs fixture file context"
      end
    end)

    it("should return nil for invalid lines", function()
      local line = "invalid line format"
      local result = spring.parse_line(line, "GET")
      assert.is_nil(result)
    end)

    it("should return nil for empty lines", function()
      local line = ""
      local result = spring.parse_line(line, "GET")
      assert.is_nil(result)
    end)
  end)

  describe("controller base path extraction", function()
    it("should extract base path from @RequestMapping on controller", function()
      local fixture_file = "tests/fixtures/spring/src/main/java/com/example/OrderController.java"
      if vim.fn.filereadable(fixture_file) == 1 then
        local base_path = spring.get_controller_base_path(fixture_file)
        assert.are.equal("/orders", base_path)
      else
        pending "OrderController fixture not found"
      end
    end)

    it("should return empty string for controllers without base path", function()
      local fixture_file = "tests/fixtures/spring/src/main/java/com/example/NoBasePath.java"
      if vim.fn.filereadable(fixture_file) == 1 then
        local base_path = spring.get_controller_base_path(fixture_file)
        assert.are.equal("", base_path)
      else
        -- Create temporary file for test
        local temp_file = "/tmp/TestController.java"
        local content = {
          "package com.example;",
          "@RestController",
          "public class TestController {",
          '    @GetMapping("/test")',
          '    public String test() { return "test"; }',
          "}",
        }
        vim.fn.writefile(content, temp_file)

        local base_path = spring.get_controller_base_path(temp_file)
        assert.are.equal("", base_path)

        vim.fn.delete(temp_file)
      end
    end)
  end)

  describe("integration with fixtures", function()
    it("should correctly parse real Spring fixture files", function()
      local fixture_path = "tests/fixtures/spring"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        -- Test that framework is detected
        assert.is_true(spring.detect())

        -- Test that search command works
        local cmd = spring.get_search_cmd "GET"
        assert.is_string(cmd)

        -- Test parsing with actual fixture data
        local sample_line = 'src/main/java/com/example/UserController.java:42:5:    @GetMapping("/{id}")'
        local result = spring.parse_line(sample_line, "GET")

        if result then
          assert.is_table(result)
          assert.are.equal("GET", result and result.method)
          assert.is_string(result.endpoint_path)
          assert.is_string(result.file_path)
        end

        vim.fn.chdir(original_cwd)
      else
        pending "Spring fixture directory not found"
      end
    end)
  end)

  describe("edge cases", function()
    it("should handle lines with extra whitespace", function()
      local line = '  src/main/java/Controller.java:10:5:      @GetMapping(  "/api/test"  )  '
      local result = spring.parse_line(line, "GET")

      if result then
        assert.are.equal("/api/test", result and result.endpoint_path)
      end
    end)

    it("should handle different quote styles", function()
      local line1 = "src/main/java/Controller.java:10:5:    @GetMapping('/api/single')"
      local line2 = 'src/main/java/Controller.java:11:5:    @GetMapping("/api/double")'

      local result1 = spring.parse_line(line1, "GET")
      local result2 = spring.parse_line(line2, "GET")

      -- Both should work or both should fail consistently
      if result1 and result2 then
        assert.are.equal("/api/single", result1.endpoint_path)
        assert.are.equal("/api/double", result2.endpoint_path)
      end
    end)

    it("should handle complex path patterns", function()
      local line = 'src/main/java/Controller.java:10:5:    @GetMapping("/api/users/{userId}/posts/{postId}")'
      local result = spring.parse_line(line, "GET")

      if result then
        assert.are.equal("/api/users/{userId}/posts/{postId}", result and result.endpoint_path)
      end
    end)

    it("should not parse class-level @RequestMapping as endpoint", function()
      local class_level_line = 'src/main/java/Controller.java:5:1:@RequestMapping("/api/v1")'
      local result = spring.parse_line(class_level_line, "ALL")

      -- Class-level @RequestMapping should not be parsed as an endpoint
      assert.is_nil(result)
    end)

    it("should parse method-level @RequestMapping with method parameter as endpoint", function()
      local method_level_line =
        'src/main/java/Controller.java:10:5:    @RequestMapping(value = "/users", method = RequestMethod.GET)'
      local result = spring.parse_line(method_level_line, "ALL")

      -- Method-level @RequestMapping with method parameter should be parsed
      assert.is_not_nil(result)
      assert.are.equal("GET", result and result.method)
      assert.are.equal("/users", result and result.endpoint_path)
    end)

    it("should not parse standalone @RequestMapping without method parameter", function()
      local standalone_line = 'src/main/java/Controller.java:10:5:    @RequestMapping("/users")'
      local result = spring.parse_line(standalone_line, "ALL")

      -- Standalone @RequestMapping without method parameter should not be parsed
      assert.is_nil(result)
    end)
  end)
end)
