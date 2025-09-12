describe("Scanner service", function()
  local endpoint = require "endpoint"
  local scanner = require "endpoint.services.scanner"

  before_each(function()
    endpoint.setup()
    -- Clear cache before each test
    scanner.clear_cache()
    -- Reset session config before each test
    local state = require "endpoint.core.state"
    state.set_config {
      framework = "auto",
      cache_mode = "none",
      debug = false,
    }
  end)

  describe("basic functionality", function()
    it("should export expected API", function()
      assert.is_function(scanner.scan)
      assert.is_function(scanner.scan_all)
      assert.is_function(scanner.get_list)
      assert.is_function(scanner.prepare_preview)
      assert.is_function(scanner.clear_cache)
      assert.is_function(scanner.get_cache_data)
    end)

    it("should return cache data structure", function()
      local cache_data = scanner.get_cache_data()
      assert.is_table(cache_data)
      assert.is_table(cache_data.find_table)
      assert.is_table(cache_data.preview_table)
    end)
  end)
  --
  describe("Symfony framework integration", function()
    it("should scan Symfony endpoints correctly", function()
      local fixture_path = "tests/fixtures/symfony"
      local state = require "endpoint.core.state"
      state.set_config {
        framework = "symfony",
      }
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        local results = scanner.get_list "GET"

        -- Should find some endpoints
        assert.is_true(#results > 0, "Should return table even if empty")

        vim.fn.chdir(original_cwd)
      else
        pending "Symfony fixture directory not found"
      end
    end)
  end)
  --
  -- describe("cache management", function()
  --   it("should clear cache properly", function()
  --     -- Add some mock data to cache first
  --     local cache = require "endpoint.services.cache"
  --     cache.create_find_table_entry("/test/file.rb", "GET")
  --     cache.insert_to_find_table {
  --       path = "/test/file.rb",
  --       annotation = "GET",
  --       value = "/test/endpoint",
  --       line_number = 1,
  --       column = 1,
  --     }
  --
  --     -- Verify cache has data
  --     local cache_data = scanner.get_cache_data()
  --     local has_data = next(cache_data.find_table) ~= nil
  --
  --     -- Clear cache
  --     scanner.clear_cache()
  --
  --     -- Verify cache is empty
  --     cache_data = scanner.get_cache_data()
  --     local is_empty = next(cache_data.find_table) == nil
  --
  --     assert.is_true(is_empty, "Cache should be empty after clear")
  --   end)
  -- end)
  --
  -- describe("batch scanning", function()
  --   it("should scan all methods without errors", function()
  --     local fixture_path = "tests/fixtures/rails"
  --     if vim.fn.isdirectory(fixture_path) == 1 then
  --       local original_cwd = vim.fn.getcwd()
  --       vim.fn.chdir(fixture_path)
  --
  --       -- Should not throw errors
  --       assert.has_no_error(function()
  --         scanner.scan_all()
  --       end)
  --
  --       vim.fn.chdir(original_cwd)
  --     else
  --       pending "Rails fixture directory not found"
  --     end
  --   end)
  -- end)
  --
  -- describe("error handling", function()
  --   it("should handle missing framework gracefully", function()
  --     -- Change to directory without any framework files
  --     local temp_dir = "/tmp/test_empty_dir_" .. os.time()
  --     vim.fn.mkdir(temp_dir, "p")
  --     local original_cwd = vim.fn.getcwd()
  --     vim.cmd("cd " .. temp_dir)
  --
  --     -- Should not throw errors
  --     assert.has_no_error(function()
  --       scanner.scan "GET"
  --     end)
  --
  --     local results = scanner.get_list "GET"
  --     assert.is_table(results)
  --     assert.are.equal(0, #results)
  --
  --     -- Cleanup
  --     vim.cmd("cd " .. original_cwd)
  --     vim.fn.delete(temp_dir, "rf")
  --   end)
  --
  --   it("should handle invalid methods gracefully", function()
  --     assert.has_no_error(function()
  --       scanner.scan "INVALID_METHOD"
  --     end)
  --
  --     local results = scanner.get_list "INVALID_METHOD"
  --     assert.is_table(results)
  --     assert.are.equal(0, #results)
  --   end)
  -- end)
  --
  -- describe("Spring framework integration", function()
  --   it("should scan Spring endpoints correctly", function()
  --     local fixture_path = "tests/fixtures/spring"
  --     local session = require "endpoint.core.state"
  --     session.set_config {
  --       framework = "spring",
  --     }
  --     if vim.fn.isdirectory(fixture_path) == 1 then
  --       local original_cwd = vim.fn.getcwd()
  --       vim.fn.chdir(fixture_path)
  --
  --       scanner.scan "GET"
  --       local results = scanner.get_list "GET"
  --
  --       -- Should find some endpoints
  --       assert.is_true(#results >= 0, "Should return table even if empty")
  --
  --       vim.fn.chdir(original_cwd)
  --     else
  --       pending "Spring fixture directory not found"
  --     end
  --   end)
  -- end)
  --
  -- describe("NestJS framework integration", function()
  --   it("should scan NestJS endpoints correctly", function()
  --     local fixture_path = "tests/fixtures/nestjs"
  --     local session = require "endpoint.core.state"
  --     session.set_config {
  --       framework = "nestjs",
  --     }
  --     if vim.fn.isdirectory(fixture_path) == 1 then
  --       local original_cwd = vim.fn.getcwd()
  --       vim.fn.chdir(fixture_path)
  --
  --       scanner.scan "GET"
  --       local results = scanner.get_list "GET"
  --
  --       -- Should find some endpoints
  --       assert.is_true(#results >= 0, "Should return table even if empty")
  --
  --       vim.fn.chdir(original_cwd)
  --     else
  --       pending "NestJS fixture directory not found"
  --     end
  -- end)
  -- end)
end)
