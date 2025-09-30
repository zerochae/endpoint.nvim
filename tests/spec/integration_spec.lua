-- Integration tests that test the full endpoint.nvim functionality
local EndpointManager = require "endpoint.manager.EndpointManager"
local config = require "endpoint.config"

describe("Endpoint.nvim Integration Tests", function()
  local endpoint_manager

  before_each(function()
    endpoint_manager = EndpointManager:new()
    -- Setup with default config
    endpoint_manager:setup {}
  end)

  describe("Real Project Detection", function()
    it("should detect Spring project from fixtures", function()
      -- Change to Spring fixture directory
      local original_cwd = vim.fn.getcwd()
      local spring_fixture_path = original_cwd .. "/tests/fixtures/spring"

      -- Check if fixture directory exists
      if vim.fn.isdirectory(spring_fixture_path) == 0 then
        pending "Spring fixture directory not found"
        return
      end

      vim.fn.chdir(spring_fixture_path)

      local detected_frameworks = endpoint_manager:detect_project_frameworks()

      -- Should detect Spring framework
      local found_spring = false
      for _, framework in ipairs(detected_frameworks) do
        if framework:get_name() == "spring" then
          found_spring = true
          break
        end
      end

      assert.is_true(found_spring, "Should detect Spring framework in fixture project")

      -- Restore original directory
      vim.fn.chdir(original_cwd)
    end)

    it("should detect Express project from fixtures", function()
      -- Change to Express fixture directory
      local original_cwd = vim.fn.getcwd()
      local express_fixture_path = original_cwd .. "/tests/fixtures/express"

      -- Check if fixture directory exists
      if vim.fn.isdirectory(express_fixture_path) == 0 then
        pending "Express fixture directory not found"
        return
      end

      vim.fn.chdir(express_fixture_path)

      local detected_frameworks = endpoint_manager:detect_project_frameworks()

      -- Should detect Express framework
      local found_express = false
      for _, framework in ipairs(detected_frameworks) do
        if framework:get_name() == "express" then
          found_express = true
          break
        end
      end

      assert.is_true(found_express, "Should detect Express framework in fixture project")

      -- Restore original directory
      vim.fn.chdir(original_cwd)
    end)
  end)

  describe("Real Project Scanning", function()
    it("should scan Spring project and find endpoints", function()
      -- Use Spring framework directly instead of changing directory
      local spring_framework = nil
      for _, framework in ipairs(endpoint_manager:get_registered_frameworks()) do
        if framework:get_name() == "spring" then
          spring_framework = framework
          break
        end
      end

      if not spring_framework then
        pending "Spring framework not registered"
        return
      end

      -- Mock the file system to simulate Spring project
      local fs = require "endpoint.utils.fs"
      local original_has_file = fs.has_file
      local original_file_contains = fs.file_contains

      fs.has_file = function(files)
        if type(files) == "table" then
          for _, file in ipairs(files) do
            if file == "pom.xml" or file == "build.gradle" or file == "application.properties" then
              return true
            end
          end
        end
        return false
      end

      fs.file_contains = function(filepath, pattern)
        if filepath == "pom.xml" and pattern == "spring-boot" then
          return true
        end
        return false
      end

      local endpoints = spring_framework:scan {}

      -- Restore original functions
      fs.has_file = original_has_file
      fs.file_contains = original_file_contains

      -- Should find multiple endpoints
      assert.is_true(#endpoints > 0, "Should find endpoints in Spring fixture project")

      -- Verify endpoint structure
      for _, endpoint in ipairs(endpoints) do
        assert.is_string(endpoint.method, "Endpoint should have method")
        assert.is_string(endpoint.endpoint_path, "Endpoint should have path")
        assert.is_string(endpoint.file_path, "Endpoint should have file path")
        assert.is_number(endpoint.line_number, "Endpoint should have line number")
        assert.equals("spring", endpoint.framework, "Endpoint should have correct framework")
      end
    end)

    it("should scan Express project and find endpoints", function()
      -- Use Express framework directly instead of changing directory
      local express_framework = nil
      for _, framework in ipairs(endpoint_manager:get_registered_frameworks()) do
        if framework:get_name() == "express" then
          express_framework = framework
          break
        end
      end

      if not express_framework then
        pending "Express framework not registered"
        return
      end

      -- Mock the file system to simulate Express project
      local fs = require "endpoint.utils.fs"
      local original_has_file = fs.has_file
      local original_file_contains = fs.file_contains

      fs.has_file = function(files)
        if type(files) == "table" then
          for _, file in ipairs(files) do
            if file == "package.json" or file == "server.js" or file == "app.js" then
              return true
            end
          end
        end
        return false
      end

      fs.file_contains = function(filepath, pattern)
        if filepath == "package.json" and pattern == "express" then
          return true
        end
        return false
      end

      local endpoints = express_framework:scan {}

      -- Restore original functions
      fs.has_file = original_has_file
      fs.file_contains = original_file_contains

      -- Should find multiple endpoints
      assert.is_true(#endpoints > 0, "Should find endpoints in Express fixture project")

      -- Verify endpoint structure
      for _, endpoint in ipairs(endpoints) do
        assert.is_string(endpoint.method, "Endpoint should have method")
        assert.is_string(endpoint.endpoint_path, "Endpoint should have path")
        assert.is_string(endpoint.file_path, "Endpoint should have file path")
        assert.is_number(endpoint.line_number, "Endpoint should have line number")
        assert.equals("express", endpoint.framework, "Endpoint should have correct framework")
      end
    end)
  end)

  describe("Method Filtering", function()
    it("should filter endpoints by HTTP method", function()
      -- Use Spring framework directly
      local spring_framework = nil
      for _, framework in ipairs(endpoint_manager:get_registered_frameworks()) do
        if framework:get_name() == "spring" then
          spring_framework = framework
          break
        end
      end

      if not spring_framework then
        pending "Spring framework not registered"
        return
      end

      local get_endpoints = spring_framework:scan { method = "GET" }
      local post_endpoints = spring_framework:scan { method = "POST" }

      -- All GET endpoints should have GET method
      for _, endpoint in ipairs(get_endpoints) do
        assert.equals("GET", endpoint.method, "Filtered endpoint should be GET")
      end

      -- All POST endpoints should have POST method
      for _, endpoint in ipairs(post_endpoints) do
        assert.equals("POST", endpoint.method, "Filtered endpoint should be POST")
      end
    end)
  end)

  describe("Cache Functionality", function()
    it("should cache and retrieve endpoints", function()
      -- Test cache functionality without changing directory
      local cache_manager = endpoint_manager.cache_manager

      -- Clear cache first
      cache_manager:clear()

      -- Test cache operations
      local test_endpoints = {
        { method = "GET", endpoint_path = "/test", file_path = "test.java", line_number = 1, framework = "spring" },
      }

      -- Save to cache
      cache_manager:save_endpoints(test_endpoints, "GET")

      -- Retrieve from cache
      local cached_endpoints = cache_manager:get_endpoints "GET"

      -- Results should be the same
      assert.equals(#test_endpoints, #cached_endpoints, "Cached results should match original results")
    end)

    it("should respect force refresh", function()
      -- Test force refresh functionality
      local cache_manager = endpoint_manager.cache_manager

      -- Clear cache first
      cache_manager:clear()

      -- Test cache operations
      local test_endpoints = {
        { method = "GET", endpoint_path = "/test", file_path = "test.java", line_number = 1, framework = "spring" },
      }

      -- Save to cache
      cache_manager:save_endpoints(test_endpoints, "GET")

      -- Test cache validity
      local is_valid_result = cache_manager:is_valid "GET"
      assert.is_not_nil(is_valid_result, "is_valid should return a boolean value")
      assert.is_true(is_valid_result, "Cache should be valid after saving")

      -- Clear cache
      cache_manager:clear()

      -- Cache should be invalid after clearing
      local is_invalid_result = cache_manager:is_valid "GET"
      assert.is_not_nil(is_invalid_result, "is_valid should return a boolean value")
      assert.is_false(is_invalid_result, "Cache should be invalid after clearing")
    end)
  end)

  describe("Error Handling", function()
    it("should handle non-existent project gracefully", function()
      -- Test error handling without changing directory
      local spring_framework = nil
      for _, framework in ipairs(endpoint_manager:get_registered_frameworks()) do
        if framework:get_name() == "spring" then
          spring_framework = framework
          break
        end
      end

      if not spring_framework then
        pending "Spring framework not registered"
        return
      end

      -- Mock file system to simulate non-existent project
      local fs = require "endpoint.utils.fs"
      local original_has_file = fs.has_file

      fs.has_file = function(files)
        return false -- Simulate no files found
      end

      local endpoints = spring_framework:scan {}

      -- Restore original function
      fs.has_file = original_has_file

      -- Should return empty list without crashing
      assert.is_table(endpoints, "Should return table even for non-existent project")
      assert.equals(0, #endpoints, "Should return empty list for non-existent project")
    end)

    it("should handle empty project gracefully", function()
      -- Create temporary empty directory
      local temp_dir = "/tmp/endpoint-test-empty"
      vim.fn.mkdir(temp_dir, "p")

      local original_cwd = vim.fn.getcwd()
      vim.fn.chdir(temp_dir)

      local endpoints = endpoint_manager:scan_all_endpoints {}

      -- Should return empty list without crashing
      assert.is_table(endpoints, "Should return table even for empty project")
      assert.equals(0, #endpoints, "Should return empty list for empty project")

      -- Cleanup
      vim.fn.chdir(original_cwd)
      vim.fn.delete(temp_dir, "rf")
    end)
  end)

  describe("Performance", function()
    it("should handle large number of endpoints efficiently", function()
      -- Test performance without changing directory
      local spring_framework = nil
      for _, framework in ipairs(endpoint_manager:get_registered_frameworks()) do
        if framework:get_name() == "spring" then
          spring_framework = framework
          break
        end
      end

      if not spring_framework then
        pending "Spring framework not registered"
        return
      end

      local start_time = vim.loop.hrtime()
      local endpoints = spring_framework:scan {}
      local end_time = vim.loop.hrtime()

      local scan_time_ms = (end_time - start_time) / 1000000 -- Convert to milliseconds

      -- Should complete scanning in reasonable time (less than 5 seconds)
      assert.is_true(scan_time_ms < 5000, "Should scan endpoints in reasonable time")

      -- Should return a table (even if empty)
      assert.is_table(endpoints, "Should return table")
    end)
  end)
end)

