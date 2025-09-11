describe("Cache system behavior", function()
  local cache = require("endpoint.services.cache")
  local endpoint = require("endpoint.services.endpoint")
  
  -- Mock data for testing
  local mock_results = {
    { value = "GET /api/users", method = "GET", path = "/api/users", file_path = "test.rb", line_number = 1 },
    { value = "POST /api/users", method = "POST", path = "/api/users", file_path = "test.rb", line_number = 5 }
  }
  
  -- Helper function to reset cache state
  local function reset_cache()
    cache.clear_tables()
  end
  
  before_each(function()
    reset_cache()
  end)
  
  describe("cache mode: none", function()
    local none_config = { cache_mode = "none" }
    
    it("should never return cached results", function()
      local cache_key = "GET"
      
      -- Manually set some data in internal cache (simulating previous cached data)
      cache.set_cached_results(cache_key, mock_results, { cache_mode = "session" })
      
      -- With "none" mode, should always return nil (no cache)
      local cached = cache.get_cached_results(cache_key, none_config)
      assert.is_nil(cached)
    end)
    
    it("should never store cached results", function()
      local cache_key = "POST"
      
      -- Try to cache results with "none" mode
      cache.set_cached_results(cache_key, mock_results, none_config)
      
      -- Should not be cached, even with session mode retrieval
      local cached = cache.get_cached_results(cache_key, { cache_mode = "session" })
      assert.is_nil(cached)
    end)
    
    it("should bypass cache completely in endpoint service", function()
      -- Mock the create_endpoint_table function to track calls
      local create_calls = 0
      local original_create = endpoint.create_endpoint_table
      endpoint.create_endpoint_table = function(method, config)
        create_calls = create_calls + 1
        return mock_results
      end
      
      -- First call
      local results1 = endpoint.get_endpoints("GET", none_config)
      assert.are.equal(1, create_calls)
      assert.are.same(mock_results, results1)
      
      -- Second call should also create new results (no cache)
      local results2 = endpoint.get_endpoints("GET", none_config)
      assert.are.equal(2, create_calls)
      assert.are.same(mock_results, results2)
      
      -- Restore original function
      endpoint.create_endpoint_table = original_create
    end)
  end)
  
  describe("cache mode: session", function()
    local session_config = { cache_mode = "session" }
    
    it("should store and retrieve cached results", function()
      local cache_key = "GET"
      
      -- Set cached results
      cache.set_cached_results(cache_key, mock_results, session_config)
      
      -- Should retrieve cached results
      local cached = cache.get_cached_results(cache_key, session_config)
      assert.are.same(mock_results, cached)
    end)
    
    it("should return nil when no cache exists", function()
      local cache_key = "DELETE"
      
      -- No cached data exists
      local cached = cache.get_cached_results(cache_key, session_config)
      assert.is_nil(cached)
    end)
    
    it("should use cache in endpoint service when available", function()
      -- Mock the create_endpoint_table function
      local create_calls = 0
      local original_create = endpoint.create_endpoint_table
      endpoint.create_endpoint_table = function(method, config)
        create_calls = create_calls + 1
        return mock_results
      end
      
      -- Pre-populate cache
      cache.set_cached_results("GET", mock_results, session_config)
      cache.update_cache_timestamp("GET")
      
      -- First call should use cache (no create call)
      local results1 = endpoint.get_endpoints("GET", session_config)
      assert.are.equal(0, create_calls)
      assert.are.same(mock_results, results1)
      
      -- Clear cache and call again
      reset_cache()
      local results2 = endpoint.get_endpoints("GET", session_config)
      assert.are.equal(1, create_calls)
      assert.are.same(mock_results, results2)
      
      -- Restore original function
      endpoint.create_endpoint_table = original_create
    end)
  end)
  
  describe("cache mode: persistent", function()
    local persistent_config = { cache_mode = "persistent" }
    
    it("should store and retrieve cached results", function()
      local cache_key = "PUT"
      
      -- Set cached results
      cache.set_cached_results(cache_key, mock_results, persistent_config)
      
      -- Should retrieve cached results
      local cached = cache.get_cached_results(cache_key, persistent_config)
      assert.are.same(mock_results, cached)
    end)
    
    it("should handle cache validation correctly", function()
      local cache_key = "PATCH"
      
      -- Set cached results with timestamp
      cache.set_cached_results(cache_key, mock_results, persistent_config)
      cache.update_cache_timestamp(cache_key)
      
      -- Should be valid cache
      local is_valid = cache.is_cache_valid(cache_key)
      assert.is_true(is_valid)
      
      -- Should use cache
      local should_use = cache.should_use_cache(cache_key)
      assert.is_true(should_use)
    end)
  end)
  
  describe("cache mode transitions", function()
    it("should handle switching between different cache modes", function()
      local cache_key = "GET"
      
      -- Start with session cache
      cache.set_cached_results(cache_key, mock_results, { cache_mode = "session" })
      local cached_session = cache.get_cached_results(cache_key, { cache_mode = "session" })
      assert.are.same(mock_results, cached_session)
      
      -- Switch to "none" mode - should return nil
      local cached_none = cache.get_cached_results(cache_key, { cache_mode = "none" })
      assert.is_nil(cached_none)
      
      -- Switch to persistent mode - should still have data (if valid)
      cache.update_cache_timestamp(cache_key)
      local cached_persistent = cache.get_cached_results(cache_key, { cache_mode = "persistent" })
      assert.are.same(mock_results, cached_persistent)
    end)
  end)
  
  describe("cache interface", function()
    it("should have consistent get_cached_results behavior", function()
      local cache_key = "TEST"
      
      -- Test with nil config (should use default)
      local cached_nil = cache.get_cached_results(cache_key, nil)
      assert.is_nil(cached_nil) -- No cache exists yet
      
      -- Test with empty config
      local cached_empty = cache.get_cached_results(cache_key, {})
      assert.is_nil(cached_empty)
    end)
    
    it("should have consistent set_cached_results behavior", function()
      local cache_key = "TEST"
      
      -- Should not error with nil config
      assert.has_no_error(function()
        cache.set_cached_results(cache_key, mock_results, nil)
      end)
      
      -- Should not error with empty config
      assert.has_no_error(function()
        cache.set_cached_results(cache_key, mock_results, {})
      end)
    end)
  end)
  
  describe("cache clear operations", function()
    it("should clear all cache data correctly", function()
      -- Populate cache with different modes
      cache.set_cached_results("GET", mock_results, { cache_mode = "session" })
      cache.set_cached_results("POST", mock_results, { cache_mode = "persistent" })
      cache.update_cache_timestamp("GET")
      cache.update_cache_timestamp("POST")
      
      -- Verify data exists
      local cached_get = cache.get_cached_results("GET", { cache_mode = "session" })
      local cached_post = cache.get_cached_results("POST", { cache_mode = "persistent" })
      assert.are.same(mock_results, cached_get)
      assert.are.same(mock_results, cached_post)
      
      -- Clear cache
      cache.clear_tables()
      
      -- Verify data is cleared
      local cleared_get = cache.get_cached_results("GET", { cache_mode = "session" })
      local cleared_post = cache.get_cached_results("POST", { cache_mode = "persistent" })
      assert.is_nil(cleared_get)
      assert.is_nil(cleared_post)
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