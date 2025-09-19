---@class endpoint.CacheManager
local CacheManager = {}
CacheManager.__index = CacheManager

function CacheManager:new()
  local cache_instance = setmetatable({}, self)
  cache_instance.cached_endpoints = {}
  cache_instance.cache_timestamp = 0
  return cache_instance
end

function CacheManager:is_valid()
  return #self.cached_endpoints > 0
end

function CacheManager:get_endpoints()
  return self.cached_endpoints
end

function CacheManager:save_endpoints(endpoints)
  self.cached_endpoints = endpoints
  self.cache_timestamp = vim.loop.hrtime()
end

function CacheManager:clear()
  self.cached_endpoints = {}
  self.cache_timestamp = 0
end

function CacheManager:get_stats()
  return {
    total_endpoints = #self.cached_endpoints,
    timestamp = self.cache_timestamp,
    valid = self:is_valid(),
  }
end

-- Export the CacheManager class for OOP usage
return CacheManager
