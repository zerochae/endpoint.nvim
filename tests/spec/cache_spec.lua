describe("Cache system behavior", function()
  local cache = require "endpoint.cache"

  before_each(function()
    -- Reset cache state before each test
    cache.clear()
    cache.set_mode "session" -- Default mode for tests
  end)

  describe("cache modes", function()
    it("should set and get cache mode correctly", function()
      cache.set_mode "persistent"
      assert.are.equal("persistent", cache.get_mode())

      cache.set_mode "session"
      assert.are.equal("session", cache.get_mode())

      cache.set_mode "none"
      assert.are.equal("none", cache.get_mode())
    end)
  end)

  describe("endpoint storage and retrieval", function()
    it("should store and retrieve single endpoint", function()
      cache.set_mode "session"

      local endpoint = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 10,
        column = 5,
      }

      cache.save_endpoint("GET", endpoint)

      local results = cache.get_endpoints "GET"
      assert.are.equal(1, #results)
      assert.are.equal("/api/users", results[1].endpoint_path)
      assert.are.equal("GET", results[1].method)
      assert.are.equal("/path/to/controller.java", results[1].file_path)
      assert.are.equal(10, results[1].line_number)
      assert.are.equal(5, results[1].column)
    end)

    it("should store multiple endpoints for same method", function()
      cache.set_mode "session"

      local endpoint1 = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 10,
        column = 5,
      }

      local endpoint2 = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/posts",
        line_number = 20,
        column = 5,
      }

      cache.save_endpoint("GET", endpoint1)
      cache.save_endpoint("GET", endpoint2)

      local results = cache.get_endpoints "GET"
      assert.are.equal(2, #results)
    end)

    it("should store endpoints for different methods", function()
      cache.set_mode "session"

      local get_endpoint = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 10,
        column = 5,
      }

      local post_endpoint = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 20,
        column = 5,
      }

      cache.save_endpoint("GET", get_endpoint)
      cache.save_endpoint("POST", post_endpoint)

      local get_results = cache.get_endpoints "GET"
      local post_results = cache.get_endpoints "POST"

      assert.are.equal(1, #get_results)
      assert.are.equal(1, #post_results)
      assert.are.equal("GET", get_results[1].method)
      assert.are.equal("POST", post_results[1].method)
    end)

    it("should handle ALL method to return all endpoints", function()
      cache.set_mode "session"

      local get_endpoint = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 10,
        column = 5,
      }

      local post_endpoint = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/posts",
        line_number = 20,
        column = 5,
      }

      cache.save_endpoint("GET", get_endpoint)
      cache.save_endpoint("POST", post_endpoint)

      local all_results = cache.get_endpoints "ALL"
      assert.are.equal(2, #all_results)

      -- Should contain both GET and POST endpoints
      local methods = {}
      for _, result in ipairs(all_results) do
        table.insert(methods, result and result.method)
      end

      assert.is_true(vim.tbl_contains(methods, "GET"))
      assert.is_true(vim.tbl_contains(methods, "POST"))
    end)
  end)

  describe("duplicate prevention", function()
    it("should prevent duplicate endpoints with same path and location", function()
      cache.set_mode "session"

      local endpoint = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 10,
        column = 5,
      }

      -- Save same endpoint twice
      cache.save_endpoint("GET", endpoint)
      cache.save_endpoint("GET", endpoint)

      local results = cache.get_endpoints "GET"
      assert.are.equal(1, #results) -- Should only have one copy
    end)

    it("should allow different endpoints with same path but different locations", function()
      cache.set_mode "session"

      local endpoint1 = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 10,
        column = 5,
      }

      local endpoint2 = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 20, -- Different line
        column = 5,
      }

      cache.save_endpoint("GET", endpoint1)
      cache.save_endpoint("GET", endpoint2)

      local results = cache.get_endpoints "GET"
      assert.are.equal(2, #results) -- Should have both since different locations
    end)

    it("should handle backward compatibility with old cache format", function()
      cache.set_mode "session"

      -- Simulate old cache format by directly inserting into find_table
      local find_table = cache.get_find_table()
      find_table["/path/to/controller.java"] = {
        GET = {
          -- Old format: just an array
          { value = "/api/legacy", line_number = 5, column = 1 },
        },
      }

      -- Now save a new endpoint - should convert old format
      local new_endpoint = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/new",
        line_number = 10,
        column = 5,
      }

      cache.save_endpoint("GET", new_endpoint)

      local results = cache.get_endpoints "GET"
      assert.are.equal(2, #results) -- Should have both legacy and new

      -- Check that endpoints are correct
      local paths = {}
      for _, result in ipairs(results) do
        table.insert(paths, result and result.endpoint_path)
      end

      assert.is_true(vim.tbl_contains(paths, "/api/legacy"))
      assert.is_true(vim.tbl_contains(paths, "/api/new"))
    end)
  end)

  describe("cache validation", function()
    it("should return false for none mode", function()
      cache.set_mode "none"

      local endpoint = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 10,
        column = 5,
      }

      cache.save_endpoint("GET", endpoint)

      assert.is_false(cache.is_valid "GET")
    end)

    it("should validate session mode with timestamp", function()
      cache.set_mode "session"

      -- Initially should be invalid
      assert.is_false(cache.is_valid "GET")

      local endpoint = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 10,
        column = 5,
      }

      cache.save_endpoint("GET", endpoint)

      -- Should be valid after saving
      assert.is_true(cache.is_valid "GET")
    end)

    it("should validate persistent mode based on data existence", function()
      cache.set_mode "persistent"

      -- Initially should be invalid
      assert.is_false(cache.is_valid "GET")

      local endpoint = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 10,
        column = 5,
      }

      cache.save_endpoint("GET", endpoint)

      -- Should be valid in persistent mode if data exists
      assert.is_true(cache.is_valid "GET")
    end)

    it("should handle ALL method validation", function()
      cache.set_mode "session"

      -- Initially should be invalid
      assert.is_false(cache.is_valid "ALL")

      local endpoint = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 10,
        column = 5,
      }

      cache.save_endpoint("GET", endpoint)

      -- Should be valid for ALL if any method has data
      assert.is_true(cache.is_valid "ALL")
    end)
  end)

  describe("preview operations", function()
    it("should save and retrieve preview data", function()
      cache.set_mode "session"

      local endpoint_key = "GET /api/users"
      cache.save_preview(endpoint_key, "/path/to/file.java", 10, 5)

      local preview = cache.get_preview(endpoint_key)
      assert.are.equal("/path/to/file.java", preview.path)
      assert.are.equal(10, preview.line_number)
      assert.are.equal(5, preview.column)
    end)
  end)

  describe("cache clearing", function()
    it("should clear all cache data", function()
      cache.set_mode "session"

      local endpoint = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 10,
        column = 5,
      }

      cache.save_endpoint("GET", endpoint)
      cache.save_preview("GET /api/users", "/path/to/file.java", 10, 5)

      -- Verify data exists
      assert.is_true(cache.is_valid "GET")
      assert.is_not_nil(cache.get_preview "GET /api/users")

      -- Clear cache
      cache.clear()

      -- Verify data is cleared
      assert.is_false(cache.is_valid "GET")
      assert.is_nil(cache.get_preview "GET /api/users")
      assert.are.equal(0, #cache.get_endpoints "GET")
    end)
  end)

  describe("cache statistics", function()
    it("should return correct statistics", function()
      cache.set_mode "session"

      local endpoint = {
        file_path = "/path/to/controller.java",
        endpoint_path = "/api/users",
        line_number = 10,
        column = 5,
      }

      cache.save_endpoint("GET", endpoint)
      cache.save_preview("GET /api/users", "/path/to/file.java", 10, 5)

      local stats = cache.get_stats()
      assert.are.equal("session", stats.mode)
      assert.are.equal(1, stats.find_entries)
      assert.are.equal(1, stats.preview_entries)
      assert.is_true(vim.tbl_contains(stats.timestamps, "GET"))
    end)
  end)
end)
