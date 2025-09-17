---@class CacheManager
local CacheManager = {}
CacheManager.__index = CacheManager

---Creates a new CacheManager instance
---@return CacheManager
function CacheManager:new()
  local cache_instance = setmetatable({}, self)
  cache_instance.cached_endpoints = {}
  cache_instance.cache_timestamp = 0
  return cache_instance
end

---Check if cache is valid (simple version - no expiration)
---@return boolean
function CacheManager:is_valid()
  return #self.cached_endpoints > 0
end

---Get cached endpoints
---@return endpoint.entry[]
function CacheManager:get_endpoints()
  return self.cached_endpoints
end

---Save endpoints to cache
---@param endpoints endpoint.entry[]
function CacheManager:save_endpoints(endpoints)
  self.cached_endpoints = endpoints
  self.cache_timestamp = vim.loop.hrtime()
end

---Clear cache
function CacheManager:clear()
  self.cached_endpoints = {}
  self.cache_timestamp = 0
end

---Get cache statistics
---@return table
function CacheManager:get_stats()
  return {
    total_endpoints = #self.cached_endpoints,
    timestamp = self.cache_timestamp,
    valid = self:is_valid()
  }
end

-- Create and return singleton instance for backward compatibility
local cache_manager = CacheManager:new()

---@class endpoint.cache
local M = {}

---Check if cache is valid
---@return boolean
function M.is_valid()
  return cache_manager:is_valid()
end

---Get cached endpoints
---@return endpoint.entry[]
function M.get_endpoints()
  return cache_manager:get_endpoints()
end

---Save endpoints to cache
---@param endpoints endpoint.entry[]
function M.save_endpoints(endpoints)
  return cache_manager:save_endpoints(endpoints)
end

---Clear cache
function M.clear()
  return cache_manager:clear()
end

---Get cache statistics
function M.get_stats()
  return cache_manager:get_stats()
end


-- Export both class and module for flexibility
M.CacheManager = CacheManager
return M