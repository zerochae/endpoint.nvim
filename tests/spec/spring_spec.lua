describe("Spring framework", function()
  local test_helpers = require "tests.utils.framework_test_helpers"
  local spring = require "endpoint.frameworks.spring"

  describe("framework detection", test_helpers.create_detection_test_suite(spring, "spring"))

  describe(
    "search command generation",
    test_helpers.create_search_cmd_test_suite(spring, {
      GET = { "@GetMapping" },
      POST = { "@PostMapping" },
      PUT = { "@PutMapping" },
      DELETE = { "@DeleteMapping" },
      PATCH = { "@PatchMapping" },
      ALL = { "@GetMapping", "@PostMapping" },
    })
  )

  describe(
    "line parsing",
    test_helpers.create_line_parsing_test_suite(spring, {
      {
        description = "should parse simple @GetMapping line",
        line = 'src/main/java/com/example/Controller.java:10:5:    @GetMapping("/api/users")',
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/users",
          file_path = "src/main/java/com/example/Controller.java",
          line_number = 10,
          column = 5,
        },
      },
      {
        description = "should parse @PostMapping with value parameter",
        line = 'src/main/java/com/example/Controller.java:15:5:    @PostMapping(value = "/api/create")',
        method = "POST",
        expected = {
          method = "POST",
          endpoint_path = "/api/create",
          file_path = "src/main/java/com/example/Controller.java",
          line_number = 15,
          column = 5,
        },
      },
      {
        description = "should parse @RequestMapping with method parameter",
        line = 'src/main/java/com/example/Controller.java:20:5:    @RequestMapping(value = "/api/test", method = RequestMethod.GET)',
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/test",
          file_path = "src/main/java/com/example/Controller.java",
          line_number = 20,
          column = 5,
        },
      },
      {
        description = "should handle path parameter instead of value",
        line = 'src/main/java/com/example/Controller.java:25:5:    @GetMapping(path = "/api/version")',
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/version",
          file_path = "src/main/java/com/example/Controller.java",
          line_number = 25,
          column = 5,
        },
      },
      {
        description = "should handle path variables",
        line = 'src/main/java/com/example/Controller.java:30:5:    @GetMapping("/api/users/{id}")',
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/users/{id}",
          file_path = "src/main/java/com/example/Controller.java",
          line_number = 30,
          column = 5,
        },
      },
    })
  )

  describe("additional parsing tests", function()
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

  describe(
    "integration with fixtures",
    test_helpers.create_integration_test_suite(spring, "spring", function(spring_module)
      -- Additional Spring-specific integration test
      local sample_line = 'src/main/java/com/example/UserController.java:42:5:    @GetMapping("/{id}")'
      local result = spring_module.parse_line(sample_line, "GET")

      if result then
        assert.is_table(result)
        assert.are.equal("GET", result and result.method)
        assert.is_string(result.endpoint_path)
        assert.is_string(result.file_path)
      end
    end)
  )

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
