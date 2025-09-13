describe("Express framework", function()
  -- Ensure package path is available for module loading
  if _G.original_package_path then
    package.path = _G.original_package_path
  end
  local express = require "endpoint.frameworks.express"

  describe("framework detection", function()
    it("should detect Express project", function()
      local fixture_path = "tests/fixtures/express"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        local detected = express.detect()
        assert.is_true(detected)

        vim.fn.chdir(original_cwd)
      else
        pending "Express fixture directory not found"
      end
    end)

    it("should not detect Express in non-Node directory", function()
      local temp_dir = "/tmp/non_express_" .. os.time()
      vim.fn.mkdir(temp_dir, "p")
      local original_cwd = vim.fn.getcwd()
      vim.fn.chdir(temp_dir)

      local detected = express.detect()
      assert.is_false(detected)

      vim.fn.chdir(original_cwd)
      vim.fn.delete(temp_dir, "rf")
    end)
  end)

  describe("search command generation", function()
    it("should generate search command for GET method", function()
      local cmd = express.get_search_cmd "GET"
      assert.is_string(cmd)
      assert.is_true(cmd:match "rg" ~= nil)
      assert.is_true(cmd:match "app\\.get" ~= nil or cmd:match "router\\.get" ~= nil)
    end)

    it("should generate search command for POST method", function()
      local cmd = express.get_search_cmd "POST"
      assert.is_string(cmd)
      assert.is_true(cmd:match "app\\.post" ~= nil or cmd:match "router\\.post" ~= nil)
    end)

    it("should generate search command for ALL method", function()
      local cmd = express.get_search_cmd "ALL"
      assert.is_string(cmd)
      -- Should contain multiple HTTP methods
      assert.is_true(cmd:match "get" ~= nil)
      assert.is_true(cmd:match "post" ~= nil)
    end)
  end)

  describe("line parsing", function()
    it("should parse simple app.get line", function()
      local line = "app.js:10:5:app.get('/api/users', (req, res) => {"
      local result = express.parse_line(line, "GET")

      assert.is_table(result)
      assert.are.equal("GET", result and result.method)
      assert.are.equal("/api/users", result and result.endpoint_path)
      assert.are.equal("app.js", result and result.file_path)
      assert.are.equal(10, result and result.line_number)
      assert.are.equal(5, result and result.column)
    end)

    it("should parse router.post line", function()
      local line = "routes/users.js:15:5:router.post('/', (req, res) => {"
      local result = express.parse_line(line, "POST")

      assert.is_table(result)
      assert.are.equal("POST", result and result.method)
      assert.are.equal("/", result and result.endpoint_path)
      assert.are.equal("routes/users.js", result and result.file_path)
    end)

    it("should parse routes with parameters", function()
      local line = "app.js:20:5:app.get('/users/:id', (req, res) => {"
      local result = express.parse_line(line, "GET")

      assert.is_table(result)
      assert.are.equal("GET", result and result.method)
      assert.are.equal("/users/:id", result and result.endpoint_path)
    end)

    it("should parse complex routes with multiple parameters", function()
      local line = "app.js:25:5:app.get('/api/v1/users/:userId/posts/:postId', (req, res) => {"
      local result = express.parse_line(line, "GET")

      assert.is_table(result)
      assert.are.equal("GET", result and result.method)
      assert.are.equal("/api/v1/users/:userId/posts/:postId", result and result.endpoint_path)
    end)

    it("should handle double quotes in routes", function()
      local line = 'app.js:30:5:app.post("/api/users", (req, res) => {'
      local result = express.parse_line(line, "POST")

      if result then
        assert.are.equal("POST", result and result.method)
        assert.are.equal("/api/users", result and result.endpoint_path)
      end
    end)

    it("should parse destructured method calls", function()
      local line = "destructured.js:10:5:get('/api/home', (req, res) => {"
      local result = express.parse_line(line, "GET")

      assert.is_table(result)
      assert.are.equal("GET", result and result.method)
      assert.are.equal("/api/home", result and result.endpoint_path)
    end)

    it("should parse destructured delete with del alias", function()
      local line = "destructured.js:15:5:del('/api/users/:id', (req, res) => {"
      local result = express.parse_line(line, "DELETE")

      assert.is_table(result)
      assert.are.equal("DELETE", result and result.method)
      assert.are.equal("/api/users/:id", result and result.endpoint_path)
    end)

    it("should parse destructured patch method", function()
      local line = "destructured.js:20:5:patch('/api/profile', (req, res) => {"
      local result = express.parse_line(line, "PATCH")

      assert.is_table(result)
      assert.are.equal("PATCH", result and result.method)
      assert.are.equal("/api/profile", result and result.endpoint_path)
    end)

    it("should return nil for invalid lines", function()
      local line = "invalid line format"
      local result = express.parse_line(line, "GET")
      assert.is_nil(result)
    end)

    it("should return nil for empty lines", function()
      local line = ""
      local result = express.parse_line(line, "GET")
      assert.is_nil(result)
    end)
  end)

  describe("integration with fixtures", function()
    it("should correctly parse real Express fixture files", function()
      local fixture_path = "tests/fixtures/express"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        -- Test that framework is detected
        assert.is_true(express.detect())

        -- Test that search command works
        local cmd = express.get_search_cmd "GET"
        assert.is_string(cmd)

        vim.fn.chdir(original_cwd)
      else
        pending "Express fixture directory not found"
      end
    end)
  end)

  describe("edge cases", function()
    it("should handle various quote styles", function()
      local line1 = "app.js:10:5:app.get('/api/single', handler)"
      local line2 = 'app.js:11:5:app.get("/api/double", handler)'

      local result1 = express.parse_line(line1, "GET")
      local result2 = express.parse_line(line2, "GET")

      if result1 and result2 then
        assert.are.equal("/api/single", result1.endpoint_path)
        assert.are.equal("/api/double", result2.endpoint_path)
      end
    end)

    it("should handle path parameters correctly", function()
      local line = "routes/users.js:15:5:router.get('/:id/posts/:postId', handler)"
      local result = express.parse_line(line, "GET")

      if result then
        assert.are.equal("/:id/posts/:postId", result and result.endpoint_path)
      end
    end)

    it("should handle root path", function()
      local line = "app.js:5:5:app.get('/', (req, res) => {"
      local result = express.parse_line(line, "GET")

      if result then
        assert.are.equal("/", result and result.endpoint_path)
      end
    end)
  end)
end)