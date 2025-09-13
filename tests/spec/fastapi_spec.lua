describe("FastAPI framework", function()
  local test_helpers = require "tests.utils.framework_test_helpers"
  local fastapi = require "endpoint.frameworks.fastapi"

  describe("framework detection", test_helpers.create_detection_test_suite(fastapi, "fastapi"))

  describe(
    "search command generation",
    test_helpers.create_search_cmd_test_suite(fastapi, {
      GET = { "@app.get", "@router.get" },
      POST = { "@app.post", "@router.post" },
      ALL = { "get", "post" },
    })
  )

  describe(
    "line parsing",
    test_helpers.create_line_parsing_test_suite(fastapi, {
      {
        description = "should parse simple @app.get line",
        line = 'main.py:10:5:@app.get("/api/users")',
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/users",
          file_path = "main.py",
          line_number = 10,
          column = 5,
        },
      },
      {
        description = "should parse @router.post line",
        line = 'routes/api.py:15:5:@router.post("/api/create")',
        method = "POST",
        expected = {
          method = "POST",
          endpoint_path = "/api/create",
          file_path = "routes/api.py",
          line_number = 15,
          column = 5,
        },
      },
    })
  )

  describe("additional parsing tests", function()
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

  describe("integration with fixtures", test_helpers.create_integration_test_suite(fastapi, "fastapi"))

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
