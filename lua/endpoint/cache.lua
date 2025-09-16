-- Simple cache implementation
local M = {}

-- In-memory cache
local cached_endpoints = {}
local cache_timestamp = 0

-- Check if cache is valid (simple version - no expiration)
function M.is_valid()
  return #cached_endpoints > 0
end

-- Get cached endpoints
---@return endpoint.entry[]
function M.get_endpoints()
  return cached_endpoints
end

-- Save endpoints to cache
---@param endpoints endpoint.entry[]
function M.save_endpoints(endpoints)
  cached_endpoints = endpoints
  cache_timestamp = vim.loop.hrtime()
end

-- Clear cache
function M.clear()
  cached_endpoints = {}
  cache_timestamp = 0
end

-- Get cache statistics
function M.get_stats()
  return {
    total_endpoints = #cached_endpoints,
    timestamp = cache_timestamp,
    valid = M.is_valid()
  }
end

return M