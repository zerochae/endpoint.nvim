describe("Scanner functionality", function()
  local scanner = require "endpoint.scanner"
  local cache = require "endpoint.cache"

  before_each(function()
    -- Clear cache before each test
    cache.clear()
    cache.set_mode "session"
  end)

  describe("basic API", function()
    it("should export expected functions", function()
      assert.is_function(scanner.scan)
      assert.is_function(scanner.detect_framework)
      assert.is_function(scanner.prepare_preview)
      assert.is_function(scanner.get_cached_endpoints)
      assert.is_function(scanner.get_preview_data)
      assert.is_function(scanner.clear_cache)
      assert.is_function(scanner.get_cache_stats)
      assert.is_function(scanner.setup)
    end)
  end)

  describe("framework detection", function()
    it("should detect framework or return nil", function()
      local framework = scanner.detect_framework()
      -- In test environment, might not detect any framework
      assert.is_true(framework == nil or type(framework) == "table")
    end)
  end)

  describe("cache operations", function()
    it("should clear cache", function()
      -- Add some test data to cache first
      cache.save_endpoint("GET", {
        file_path = "/test/file.java",
        endpoint_path = "/api/test",
        line_number = 10,
        column = 5,
      })

      -- Verify cache has data
      assert.is_true(cache.is_valid "GET")

      -- Clear via scanner
      scanner.clear_cache()

      -- Verify cache is cleared
      assert.is_false(cache.is_valid "GET")
    end)

    it("should get cached endpoints", function()
      -- Add test data
      cache.save_endpoint("POST", {
        file_path = "/test/file.java",
        endpoint_path = "/api/create",
        line_number = 20,
        column = 5,
      })

      local results = scanner.get_cached_endpoints "POST"
      assert.are.equal(1, #results)
      assert.are.equal("/api/create", results[1].endpoint_path)
    end)

    it("should get cache statistics", function()
      -- Add test data
      cache.save_endpoint("GET", {
        file_path = "/test/file.java",
        endpoint_path = "/api/test",
        line_number = 10,
        column = 5,
      })

      local stats = scanner.get_cache_stats()
      assert.is_table(stats)
      assert.is_string(stats.mode)
      assert.is_number(stats.find_entries)
      assert.is_number(stats.preview_entries)
      assert.is_table(stats.timestamps)
    end)
  end)

  describe("preview operations", function()
    it("should prepare and retrieve preview data", function()
      local endpoints = {
        {
          method = "GET",
          endpoint_path = "/api/users",
          file_path = "/test/controller.java",
          line_number = 10,
          column = 5,
        },
      }

      scanner.prepare_preview(endpoints)

      local preview = scanner.get_preview_data "GET /api/users"
      assert.is_table(preview)
      assert.are.equal("/test/controller.java", preview.path)
      assert.are.equal(10, preview.line_number)
      assert.are.equal(5, preview.column)
    end)
  end)

  describe("setup", function()
    it("should setup scanner with config", function()
      local config = {
        cache_mode = "persistent",
      }

      local ok, err = pcall(function()
        scanner.setup(config)
      end)
      assert.is_true(ok, err)
    end)
  end)

  describe("Spring framework integration", function()
    it("should handle Spring fixture scanning", function()
      local fixture_path = "tests/fixtures/spring"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        -- Should not throw errors when scanning
        local results
        local ok, err = pcall(function()
          results = scanner.scan "GET"
        end)
        assert.is_true(ok, err)

        assert.is_table(results)
        -- Results length depends on fixture content

        vim.fn.chdir(original_cwd)
      else
        pending "Spring fixture directory not found"
      end
    end)
  end)

  describe("FastAPI framework integration", function()
    it("should handle FastAPI fixture scanning", function()
      local fixture_path = "tests/fixtures/fastapi"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        local results
        local ok, err = pcall(function()
          results = scanner.scan "GET"
        end)
        assert.is_true(ok, err)

        assert.is_table(results)

        vim.fn.chdir(original_cwd)
      else
        pending "FastAPI fixture directory not found"
      end
    end)
  end)

  describe("NestJS framework integration", function()
    it("should handle NestJS fixture scanning", function()
      local fixture_path = "tests/fixtures/nestjs"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        local results
        local ok, err = pcall(function()
          results = scanner.scan "GET"
        end)
        assert.is_true(ok, err)

        assert.is_table(results)

        vim.fn.chdir(original_cwd)
      else
        pending "NestJS fixture directory not found"
      end
    end)
  end)

  describe("Symfony framework integration", function()
    it("should handle Symfony fixture scanning", function()
      local fixture_path = "tests/fixtures/symfony"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        local results
        local ok, err = pcall(function()
          results = scanner.scan "GET"
        end)
        assert.is_true(ok, err)

        assert.is_table(results)

        vim.fn.chdir(original_cwd)
      else
        pending "Symfony fixture directory not found"
      end
    end)
  end)

  describe("error handling", function()
    it("should handle no framework detected gracefully", function()
      -- Create empty temp directory
      local temp_dir = "/tmp/endpoint_test_" .. os.time()
      vim.fn.mkdir(temp_dir, "p")
      local original_cwd = vim.fn.getcwd()
      vim.fn.chdir(temp_dir)

      local results
      local ok, err = pcall(function()
        results = scanner.scan "GET"
      end)
      assert.is_true(ok, err)

      assert.is_table(results)
      assert.are.equal(0, #results)

      -- Cleanup
      vim.fn.chdir(original_cwd)
      vim.fn.delete(temp_dir, "rf")
    end)

    it("should handle invalid methods gracefully", function()
      local results
      local ok, err = pcall(function()
        results = scanner.scan "INVALID_METHOD"
      end)
      assert.is_true(ok, err)

      assert.is_table(results)
      assert.are.equal(0, #results)
    end)
  end)

  describe("cache integration", function()
    it("should use cached results when valid", function()
      -- Manually populate cache
      cache.save_endpoint("GET", {
        file_path = "/test/controller.java",
        endpoint_path = "/api/cached",
        line_number = 15,
        column = 10,
      })

      -- Should return cached results instead of scanning
      local results = scanner.scan "GET"
      assert.are.equal(1, #results)
      assert.are.equal("/api/cached", results[1].endpoint_path)
    end)

    it("should force refresh when requested", function()
      -- Manually populate cache
      cache.save_endpoint("GET", {
        file_path = "/test/controller.java",
        endpoint_path = "/api/cached",
        line_number = 15,
        column = 10,
      })

      -- Force refresh should bypass cache
      local results = scanner.scan("GET", { force_refresh = true })
      assert.is_table(results)
      -- Results depend on detected framework and files
    end)

    it("should handle ALL method correctly", function()
      -- Add multiple methods to cache
      cache.save_endpoint("GET", {
        file_path = "/test/controller.java",
        endpoint_path = "/api/get",
        line_number = 10,
        column = 5,
      })

      cache.save_endpoint("POST", {
        file_path = "/test/controller.java",
        endpoint_path = "/api/post",
        line_number = 20,
        column = 5,
      })

      local all_results = scanner.scan "ALL"
      assert.is_true(#all_results >= 2)

      -- Should contain both methods
      local methods = {}
      for _, result in ipairs(all_results) do
        table.insert(methods, result and result.method)
      end

      assert.is_true(vim.tbl_contains(methods, "GET"))
      assert.is_true(vim.tbl_contains(methods, "POST"))
    end)
  end)
end)
