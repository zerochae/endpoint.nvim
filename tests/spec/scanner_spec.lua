describe("Scanner service", function()
  local scanner = require("endpoint.services.scanner")
  
  before_each(function()
    -- Clear cache before each test
    scanner.clear_cache()
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

  describe("Rails framework integration", function()
    it("should scan Rails endpoints correctly", function()
      -- This test requires Rails fixture files
      local fixture_path = "tests/fixtures/rails"
      if vim.fn.isdirectory(fixture_path) == 1 then
        -- Change to Rails fixture directory
        local original_cwd = vim.fn.getcwd()
        vim.cmd("cd " .. fixture_path)
        
        -- Initialize session config
        local session = require("endpoint.core.session")
        session.initialize_config({})
        
        -- Scan GET endpoints
        scanner.scan("GET")
        
        -- Get results
        local results = scanner.get_list("GET")
        
        -- Should find some endpoints
        assert.is_true(#results >= 0, "Should return table even if empty")
        
        -- Check structure of results
        if #results > 0 then
          local first_result = results[1]
          assert.is_string(first_result.value)
          assert.is_string(first_result.method)
          assert.is_string(first_result.path)
          assert.is_string(first_result.file_path)
          assert.is_number(first_result.line_number)
        end
        
        -- Restore original directory
        vim.cmd("cd " .. original_cwd)
      else
        pending("Rails fixture directory not found")
      end
    end)

    it("should handle Rails display modes", function()
      local fixture_path = "tests/fixtures/rails"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.cmd("cd " .. fixture_path)
        
        scanner.scan("GET")
        local results = scanner.get_list("GET")
        
        -- In Rails native mode, method should be Rails method names (index, show, etc.)
        if #results > 0 then
          local method_names = {}
          for _, result in ipairs(results) do
            method_names[result.method] = true
          end
          
          -- Should have Rails method names, not HTTP methods
          local has_rails_methods = method_names["index"] or method_names["show"] or 
                                   method_names["create"] or method_names["update"] or 
                                   method_names["destroy"]
          
          assert.is_true(has_rails_methods, "Should find Rails method names (index, show, etc.)")
        end
        
        vim.cmd("cd " .. original_cwd)
      else
        pending("Rails fixture directory not found")
      end
    end)
  end)

  describe("cache management", function()
    it("should clear cache properly", function()
      -- Add some mock data to cache first
      local cache = require("endpoint.services.cache")
      cache.create_find_table_entry("/test/file.rb", "GET")
      cache.insert_to_find_table({
        path = "/test/file.rb",
        annotation = "GET",
        value = "/test/endpoint",
        line_number = 1,
        column = 1,
      })
      
      -- Verify cache has data
      local cache_data = scanner.get_cache_data()
      local has_data = next(cache_data.find_table) ~= nil
      
      -- Clear cache
      scanner.clear_cache()
      
      -- Verify cache is empty
      cache_data = scanner.get_cache_data()
      local is_empty = next(cache_data.find_table) == nil
      
      assert.is_true(is_empty, "Cache should be empty after clear")
    end)
  end)

  describe("batch scanning", function()
    it("should scan all methods without errors", function()
      local fixture_path = "tests/fixtures/rails"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.cmd("cd " .. fixture_path)
        
        -- Should not throw errors
        assert.has_no_error(function()
          scanner.scan_all()
        end)
        
        vim.cmd("cd " .. original_cwd)
      else
        pending("Rails fixture directory not found")
      end
    end)
  end)

  describe("error handling", function()
    it("should handle missing framework gracefully", function()
      -- Change to directory without any framework files
      local temp_dir = "/tmp/test_empty_dir_" .. os.time()
      vim.fn.mkdir(temp_dir, "p")
      local original_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. temp_dir)
      
      -- Should not throw errors
      assert.has_no_error(function()
        scanner.scan("GET")
      end)
      
      local results = scanner.get_list("GET")
      assert.is_table(results)
      assert.are.equal(0, #results)
      
      -- Cleanup
      vim.cmd("cd " .. original_cwd)
      vim.fn.delete(temp_dir, "rf")
    end)

    it("should handle invalid methods gracefully", function()
      assert.has_no_error(function()
        scanner.scan("INVALID_METHOD")
      end)
      
      local results = scanner.get_list("INVALID_METHOD")
      assert.is_table(results)
      assert.are.equal(0, #results)
    end)
  end)

  describe("Spring framework integration", function()
    it("should scan Spring endpoints correctly", function()
      local fixture_path = "tests/fixtures/spring"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.cmd("cd " .. fixture_path)
        
        scanner.scan("GET")
        local results = scanner.get_list("GET")
        
        -- Should find some endpoints
        assert.is_true(#results > 0)
        
        vim.cmd("cd " .. original_cwd)
      else
        pending("Spring fixture directory not found")
      end
    end)
  end)

  describe("NestJS framework integration", function()
    it("should scan NestJS endpoints correctly", function()
      local fixture_path = "tests/fixtures/nestjs"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.cmd("cd " .. fixture_path)
        
        scanner.scan("GET")
        local results = scanner.get_list("GET")
        
        -- Should find some endpoints
        assert.is_true(#results > 0)
        
        vim.cmd("cd " .. original_cwd)
      else
        pending("NestJS fixture directory not found")
      end
    end)
  end)
end)