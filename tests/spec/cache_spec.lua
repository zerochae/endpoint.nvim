describe("Cache system behavior", function()
  local endpoint = require("endpoint")
  local cache = require("endpoint.services.cache")
  local scanner = require("endpoint.services.scanner")
  
  before_each(function()
    endpoint.setup()
  end)
  
  -- Helper to populate find_table directly
  local function populate_find_table(method, file_path, endpoints)
    cache.create_find_table_entry(file_path, method)
    for _, endpoint in ipairs(endpoints) do
      cache.insert_to_find_table({
        path = file_path,
        annotation = method,
        value = endpoint.path,
        line_number = endpoint.line_number,
        column = endpoint.column or 1,
      })
    end
    cache.update_cache_timestamp(method)
  end
  
  -- Helper to get results from find_table
  local function get_find_table_results(method)
    local find_table = cache.get_find_table()
    local results = {}
    for file_path, mapping_object in pairs(find_table) do
      if mapping_object[method] then
        local mappings = mapping_object[method]
        if type(mappings) == "table" then
          for _, item in ipairs(mappings) do
            table.insert(results, {
              method = method,
              path = item.value or "",
              file_path = file_path,
              line_number = item.line_number,
              column = item.column,
            })
          end
        end
      end
    end
    return results
  end
  
  -- Helper function to reset cache state
  local function reset_cache()
    cache.clear_tables()
  end
  
  before_each(function()
    reset_cache()
  end)
  
  describe("cache mode: none", function()
    local none_config = { cache_mode = "none" }
    
    it("should never use cached data", function()
      local method = "GET"
      
      -- Populate find_table with session mode first
      populate_find_table(method, "test.rb", {{ path = "/api/users", line_number = 1 }})
      
      -- With "none" mode, cache should not be considered valid
      local is_valid = cache.is_cache_valid(method, none_config)
      assert.is_false(is_valid)
      
      local should_use = cache.should_use_cache(method, none_config)
      assert.is_false(should_use)
    end)
    
    it("should use temp tables in none mode", function()
      -- In "none" mode, get_find_table should return temp table
      local find_table = cache.get_find_table()
      
      -- Should be empty initially (temp table)
      assert.are.same({}, find_table)
      
      -- Create entry in temp table mode
      cache.create_find_table_entry("test.rb", "GET")
      cache.insert_to_find_table({
        path = "test.rb",
        annotation = "GET",
        value = "/api/users",
        line_number = 1,
        column = 1,
      })
      
      -- Should now have data in temp table
      local results = get_find_table_results("GET")
      assert.is_true(#results > 0)
    end)
  end)
  
  describe("cache mode: session", function()
    local session_config = { cache_mode = "session" }
    
    it("should store and retrieve find_table data", function()
      local method = "GET"
      
      -- Populate find_table
      populate_find_table(method, "test.rb", {{ path = "/api/users", line_number = 1 }})
      
      -- Should be valid cache
      local is_valid = cache.is_cache_valid(method, session_config)
      assert.is_true(is_valid)
      
      -- Should retrieve data from find_table
      local results = get_find_table_results(method)
      assert.is_true(#results > 0)
      assert.are.equal("/api/users", results[1].path)
    end)
    
    it("should return empty when no cache exists", function()
      local method = "DELETE"
      
      -- No cached data exists
      local is_valid = cache.is_cache_valid(method, session_config)
      assert.is_false(is_valid)
      
      local results = get_find_table_results(method)
      assert.are.same({}, results)
    end)
    
    it("should persist cache across calls", function()
      local method = "GET"
      
      -- Store results
      populate_find_table(method, "test.rb", {{ path = "/api/users", line_number = 1 }})
      
      -- Should be valid
      local should_use = cache.should_use_cache(method, session_config)
      assert.is_true(should_use)
      
      -- Should persist across multiple calls
      local should_use_again = cache.should_use_cache(method, session_config)
      assert.is_true(should_use_again)
    end)
  end)
  
  describe("cache mode: persistent", function()
    local persistent_config = { cache_mode = "persistent" }
    
    it("should store and retrieve find_table data", function()
      local method = "PUT"
      
      -- Populate find_table
      populate_find_table(method, "test.rb", {{ path = "/api/users", line_number = 1 }})
      
      -- Should retrieve data from find_table
      local results = get_find_table_results(method)
      assert.is_true(#results > 0)
      assert.are.equal("/api/users", results[1].path)
    end)
    
    it("should handle cache validation correctly", function()
      local method = "PATCH"
      
      -- Populate find_table with timestamp
      populate_find_table(method, "test.rb", {{ path = "/api/users", line_number = 1 }})
      
      -- Should be valid cache
      local is_valid = cache.is_cache_valid(method, persistent_config)
      assert.is_true(is_valid)
      
      -- Should use cache
      local should_use = cache.should_use_cache(method, persistent_config)
      assert.is_true(should_use)
    end)
  end)
  
  describe("cache mode transitions", function()
    it("should handle switching between different cache modes", function()
      local method = "GET"
      
      -- Start with session cache
      populate_find_table(method, "test.rb", {{ path = "/api/users", line_number = 1 }})
      
      local should_use_session = cache.should_use_cache(method, { cache_mode = "session" })
      assert.is_true(should_use_session)
      
      -- Switch to "none" mode - should not use cache
      local should_use_none = cache.should_use_cache(method, { cache_mode = "none" })
      assert.is_false(should_use_none)
      
      -- Switch to persistent mode - should still have data (if valid)
      local should_use_persistent = cache.should_use_cache(method, { cache_mode = "persistent" })
      assert.is_true(should_use_persistent)
    end)
  end)
  
  describe("cache interface", function()
    it("should have consistent cache validation behavior", function()
      local method = "TEST"
      
      -- Test with nil config (should use default)
      local is_valid_nil = cache.is_cache_valid(method, nil)
      assert.is_false(is_valid_nil) -- No cache exists yet
      
      -- Test with empty config
      local is_valid_empty = cache.is_cache_valid(method, {})
      assert.is_false(is_valid_empty)
    end)
    
    it("should handle find_table operations without errors", function()
      local method = "TEST"
      
      -- Should not error with basic operations
      assert.has_no_error(function()
        cache.create_find_table_entry("test.rb", method)
        cache.insert_to_find_table({
          path = "test.rb",
          annotation = method,
          value = "/api/test",
          line_number = 1,
          column = 1,
        })
        cache.update_cache_timestamp(method)
      end)
    end)
  end)
  
  describe("cache clear operations", function()
    it("should clear all cache data correctly", function()
      -- Populate cache with different methods
      populate_find_table("GET", "test.rb", {{ path = "/api/users", line_number = 1 }})
      populate_find_table("POST", "test.rb", {{ path = "/api/users", line_number = 5 }})
      
      -- Verify data exists
      local results_get = get_find_table_results("GET")
      local results_post = get_find_table_results("POST")
      assert.is_true(#results_get > 0)
      assert.is_true(#results_post > 0)
      
      -- Clear cache
      cache.clear_tables()
      
      -- Verify data is cleared
      local cleared_get = get_find_table_results("GET")
      local cleared_post = get_find_table_results("POST")
      assert.are.same({}, cleared_get)
      assert.are.same({}, cleared_post)
    end)
  end)
  
  describe("default cache mode behavior", function()
    it("should use default cache mode when not specified", function()
      local default_config = require("endpoint.core.config")
      
      -- Default should be "none"
      assert.are.equal("none", default_config.cache_mode)
    end)
    
    it("should handle fallback cache mode correctly", function()
      -- Test session fallback behavior
      local session = require("endpoint.core.session")
      
      -- Should use fallback logic (implementation depends on session.lua)
      assert.has_no_error(function()
        local cache_config = session.get_config()
        -- Session config can be nil if not initialized, which is valid
        -- The important thing is that it doesn't error
      end)
    end)
  end)
end)