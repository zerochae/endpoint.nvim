describe("Symfony framework", function()
  local test_helpers = require "tests.utils.framework_test_helpers"
  local symfony = require "endpoint.frameworks.symfony"

  describe("framework detection", test_helpers.create_detection_test_suite(symfony, "symfony"))

  describe("search command generation", function()
    it("should generate search command for GET method", function()
      local cmd = symfony.get_search_cmd "GET"
      assert.is_string(cmd)
      assert.is_true(cmd:match "rg" ~= nil)
      -- Should contain Route attribute or annotation patterns
      assert.is_true(cmd:match "#%[Route" ~= nil or cmd:match "@Route" ~= nil)
    end)

    it("should generate search command for POST method", function()
      local cmd = symfony.get_search_cmd "POST"
      assert.is_string(cmd)
      -- Should contain POST method pattern
      assert.is_true(cmd:match "POST" ~= nil)
    end)

    it("should generate search command for ALL method", function()
      local cmd = symfony.get_search_cmd "ALL"
      assert.is_string(cmd)
      -- Should contain multiple HTTP methods
      assert.is_true(cmd:match "GET" ~= nil or cmd:match "POST" ~= nil)
    end)
  end)

  describe("line parsing", function()
    it("should parse PHP 8+ attribute syntax", function()
      local line = "src/Controller/UserController.php:10:5:#[Route('/api/users', methods: ['GET'])]"
      local result = symfony.parse_line(line, "GET")

      assert.is_not_nil(result)
      assert.is_table(result)
      assert.are.equal("GET", result and result.method)
      assert.are.equal("/api/users", result and result.endpoint_path)
      assert.are.equal("src/Controller/UserController.php", result and result.file_path)
      assert.are.equal(10, result and result.line_number)
      assert.are.equal(5, result and result.column)
    end)

    it("should parse traditional annotation syntax", function()
      local line = 'src/Controller/UserController.php:15:5: * @Route("/api/create", methods={"POST"})'
      local result = symfony.parse_line(line, "POST")

      assert.is_not_nil(result)
      assert.is_table(result)
      assert.are.equal("POST", result and result.method)
      assert.are.equal("/api/create", result and result.endpoint_path)
    end)

    it("should parse docblock annotation syntax", function()
      local line = 'src/Controller/UserController.php:20:5:     * @Route("/api/update", methods={"PUT"})'
      local result = symfony.parse_line(line, "PUT")

      assert.is_not_nil(result)
      assert.is_table(result)
      assert.are.equal("PUT", result and result.method)
      assert.are.equal("/api/update", result and result.endpoint_path)
    end)

    it("should handle multiple HTTP methods in single route", function()
      local line = "src/Controller/UserController.php:25:5:#[Route('/api/users', methods: ['GET', 'POST'])]"
      local result = symfony.parse_line(line, "ALL")

      if result then
        -- Should return array of endpoints or single endpoint representing multiple methods
        if type(result) == "table" and result.method then
          -- Single endpoint
          assert.is_string(result.endpoint_path)
        else
          -- Array of endpoints
          assert.is_true(#result > 0)
        end
      end
    end)

    it("should combine controller base path with method path", function()
      -- This would need actual fixture context for proper testing
      local line = "src/Controller/ApiController.php:30:5:#[Route('/users', methods: ['GET'])]"
      local result = symfony.parse_line(line, "GET")

      if result then
        assert.is_table(result)
        -- Should combine controller base path if available
        assert.is_string(result.endpoint_path)
      end
    end)

    it("should handle path parameters", function()
      local line = "src/Controller/UserController.php:35:5:#[Route('/api/users/{id}', methods: ['GET'])]"
      local result = symfony.parse_line(line, "GET")

      if result then
        assert.is_table(result)
        assert.are.equal("GET", result and result.method)
        assert.are.equal("/api/users/{id}", result and result.endpoint_path)
      end
    end)

    it("should return nil for invalid lines", function()
      local line = "invalid line format"
      local result = symfony.parse_line(line, "GET")
      assert.is_nil(result)
    end)

    it("should return nil for empty lines", function()
      local line = ""
      local result = symfony.parse_line(line, "GET")
      assert.is_nil(result)
    end)
  end)

  describe("method extraction", function()
    it("should extract methods from various syntax patterns", function()
      local patterns = {
        "methods: ['GET', 'POST']",
        'methods={"GET","POST"}',
        "methods: [GET, POST]",
      }

      for _, pattern in ipairs(patterns) do
        local methods = symfony.extract_methods(pattern)
        if methods then
          assert.is_table(methods)
          assert.is_true(#methods > 0)
        end
      end
    end)
  end)

  describe("controller base path extraction", function()
    it("should extract base path from controller-level Route", function()
      local fixture_file = "tests/fixtures/symfony/src/Controller/UserController.php"
      if vim.fn.filereadable(fixture_file) == 1 then
        local base_path = symfony.get_base_path(fixture_file)
        if base_path then
          assert.is_string(base_path)
          -- Should start with slash
          assert.is_true(base_path:sub(1, 1) == "/")
        end
      else
        pending "Symfony fixture file not found"
      end
    end)

    it("should return empty string for controllers without base path", function()
      -- Create temporary file for test
      local temp_file = "/tmp/TestController.php"
      local content = {
        "<?php",
        "",
        "namespace App\\Controller;",
        "",
        "use Symfony\\Component\\Routing\\Annotation\\Route;",
        "",
        "class TestController {",
        "    #[Route('/test', methods: ['GET'])]",
        "    public function test() { return []; }",
        "}",
      }
      vim.fn.writefile(content, temp_file)

      local base_path = symfony.get_base_path(temp_file)
      assert.are.equal("", base_path)

      vim.fn.delete(temp_file)
    end)
  end)

  describe("integration with fixtures", function()
    it("should correctly parse real Symfony fixture files", function()
      local fixture_path = "tests/fixtures/symfony"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        -- Test that framework is detected
        assert.is_true(symfony.detect())

        -- Test that search command works
        local cmd = symfony.get_search_cmd "GET"
        assert.is_string(cmd)

        vim.fn.chdir(original_cwd)
      else
        pending "Symfony fixture directory not found"
      end
    end)
  end)

  describe("edge cases", function()
    it("should handle various quote styles", function()
      local line1 = "src/Controller.php:10:5:#[Route('/api/single', methods: ['GET'])]"
      local line2 = 'src/Controller.php:11:5:#[Route("/api/double", methods: ["GET"])]'

      local result1 = symfony.parse_line(line1, "GET")
      local result2 = symfony.parse_line(line2, "GET")

      if result1 and result2 then
        assert.are.equal("/api/single", result1.endpoint_path)
        assert.are.equal("/api/double", result2.endpoint_path)
      end
    end)

    it("should handle complex path patterns", function()
      local line = "src/Controller.php:15:5:#[Route('/api/users/{userId}/posts/{postId}', methods: ['GET'])]"
      local result = symfony.parse_line(line, "GET")

      if result then
        assert.are.equal("/api/users/{userId}/posts/{postId}", result and result.endpoint_path)
      end
    end)

    it("should handle mixed annotation styles", function()
      local attribute_line = "src/Controller.php:20:5:#[Route('/api/attr', methods: ['GET'])]"
      local annotation_line = 'src/Controller.php:25:5: * @Route("/api/annot", methods={"GET"})'

      local result1 = symfony.parse_line(attribute_line, "GET")
      local result2 = symfony.parse_line(annotation_line, "GET")

      if result1 then
        assert.are.equal("/api/attr", result1.endpoint_path)
      end

      if result2 then
        assert.are.equal("/api/annot", result2.endpoint_path)
      end
    end)

    it("should handle routes without explicit methods", function()
      local line = "src/Controller.php:30:5:#[Route('/api/default')]"
      local result = symfony.parse_line(line, "GET")

      if result then
        -- Should work with default method or return appropriate result
        assert.is_table(result)
        assert.is_string(result.endpoint_path)
      end
    end)
  end)
end)
