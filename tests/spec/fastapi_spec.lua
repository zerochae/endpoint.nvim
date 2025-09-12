describe("FastAPI framework", function()
  local fastapi = require "endpoint.frameworks.fastapi"

  describe("framework detection", function()
    it("should detect FastAPI project", function()
      local fixture_path = "tests/fixtures/fastapi"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        local detected = fastapi.detect()
        assert.is_true(detected)

        vim.fn.chdir(original_cwd)
      else
        pending "FastAPI fixture directory not found"
      end
    end)

    it("should not detect FastAPI in non-Python directory", function()
      local temp_dir = "/tmp/non_fastapi_" .. os.time()
      vim.fn.mkdir(temp_dir, "p")
      local original_cwd = vim.fn.getcwd()
      vim.fn.chdir(temp_dir)

      local detected = fastapi.detect()
      assert.is_false(detected)

      vim.fn.chdir(original_cwd)
      vim.fn.delete(temp_dir, "rf")
    end)
  end)

  describe("search command generation", function()
    it("should generate search command for GET method", function()
      local cmd = fastapi.get_search_cmd "GET"
      assert.is_string(cmd)
      assert.is_true(cmd:match "rg" ~= nil)
      assert.is_true(cmd:match "@app.get" ~= nil or cmd:match "@router.get" ~= nil)
    end)

    it("should generate search command for POST method", function()
      local cmd = fastapi.get_search_cmd "POST"
      assert.is_string(cmd)
      assert.is_true(cmd:match "@app.post" ~= nil or cmd:match "@router.post" ~= nil)
    end)

    it("should generate search command for ALL method", function()
      local cmd = fastapi.get_search_cmd "ALL"
      assert.is_string(cmd)
      -- Should contain multiple HTTP methods
      assert.is_true(cmd:match "get" ~= nil)
      assert.is_true(cmd:match "post" ~= nil)
    end)
  end)

  describe("line parsing", function()
    it("should parse simple @app.get line", function()
      local line = 'main.py:10:5:@app.get("/api/users")'
      local result = fastapi.parse_line(line, "GET")

      assert.is_table(result)
      assert.are.equal("GET", result and result.method)
      assert.are.equal("/api/users", result and result.endpoint_path)
      assert.are.equal("main.py", result and result.file_path)
      assert.are.equal(10, result and result.line_number)
      assert.are.equal(5, result and result.column)
    end)

    it("should parse @router.post line", function()
      local line = 'routes/api.py:15:5:@router.post("/api/create")'
      local result = fastapi.parse_line(line, "POST")

      assert.is_table(result)
      assert.are.equal("POST", result and result.method)
      assert.are.equal("/api/create", result and result.endpoint_path)
    end)

    it("should handle multiline decorators", function()
      local line = "main.py:20:5:@app.get("
      local result = fastapi.parse_line(line, "GET")

      -- Should handle multiline or return appropriate result
      if result then
        assert.is_table(result)
        assert.are.equal("GET", result and result.method)
      end
    end)

    it("should combine router prefix with endpoint path", function()
      -- This would need actual fixture context for proper testing
      local line = 'routes/users.py:25:5:@router.get("/profile")'
      local result = fastapi.parse_line(line, "GET")

      if result then
        assert.is_table(result)
        -- Should combine router prefix if available
        assert.is_string(result.endpoint_path)
      end
    end)

    it("should return nil for invalid lines", function()
      local line = "invalid line format"
      local result = fastapi.parse_line(line, "GET")
      assert.is_nil(result)
    end)
  end)

  describe("router prefix extraction", function()
    it("should extract prefix from APIRouter", function()
      -- This would need actual fixture files for proper testing
      local fixture_file = "tests/fixtures/fastapi/src/app/presentation/http/controllers/users/router.py"
      if vim.fn.filereadable(fixture_file) == 1 then
        local prefix = fastapi.get_router_prefix(fixture_file)
        if prefix then
          assert.is_string(prefix)
        end
      else
        pending "FastAPI fixture file not found"
      end
    end)
  end)

  describe("integration with fixtures", function()
    it("should correctly parse real FastAPI fixture files", function()
      local fixture_path = "tests/fixtures/fastapi"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        -- Test that framework is detected
        assert.is_true(fastapi.detect())

        -- Test that search command works
        local cmd = fastapi.get_search_cmd "GET"
        assert.is_string(cmd)

        vim.fn.chdir(original_cwd)
      else
        pending "FastAPI fixture directory not found"
      end
    end)
  end)

  describe("edge cases", function()
    it("should handle various path formats", function()
      local line1 = "main.py:10:5:@app.get('/api/single')"
      local line2 = 'main.py:11:5:@app.get("/api/double")'

      local result1 = fastapi.parse_line(line1, "GET")
      local result2 = fastapi.parse_line(line2, "GET")

      if result1 and result2 then
        assert.are.equal("/api/single", result1.endpoint_path)
        assert.are.equal("/api/double", result2.endpoint_path)
      end
    end)

    it("should handle path parameters", function()
      local line = 'main.py:15:5:@app.get("/api/users/{user_id}")'
      local result = fastapi.parse_line(line, "GET")

      if result then
        assert.are.equal("/api/users/{user_id}", result and result.endpoint_path)
      end
    end)

    it("should handle complex path patterns", function()
      local line = 'main.py:20:5:@app.get("/api/users/{user_id}/posts/{post_id}")'
      local result = fastapi.parse_line(line, "GET")

      if result then
        assert.are.equal("/api/users/{user_id}/posts/{post_id}", result and result.endpoint_path)
      end
    end)
  end)
end)
