---@class endpoint.CacheManager
local CacheManager = {}
CacheManager.__index = CacheManager

function CacheManager:new()
  local cache_instance = setmetatable({}, self)
  cache_instance.cached_endpoints = {}
  cache_instance.cache_timestamps = {}
  return cache_instance
end

function CacheManager:_get_cache_key(method)
  return method or "all"
end

function CacheManager:is_valid(method)
  local cache_key = self:_get_cache_key(method)
  return self.cached_endpoints[cache_key] and #self.cached_endpoints[cache_key] > 0
end

function CacheManager:get_endpoints(method)
  local cache_key = self:_get_cache_key(method)
  return self.cached_endpoints[cache_key] or {}
end

function CacheManager:save_endpoints(endpoints, method)
  local cache_key = self:_get_cache_key(method)
  self.cached_endpoints[cache_key] = endpoints
  self.cache_timestamps[cache_key] = vim.loop.hrtime()
end

function CacheManager:clear()
  self.cached_endpoints = {}
  self.cache_timestamps = {}
end

function CacheManager:get_stats()
  local total_endpoints = 0
  for cache_key, endpoints in pairs(self.cached_endpoints) do
    total_endpoints = total_endpoints + #endpoints
  end

  return {
    total_endpoints = total_endpoints,
    cache_keys = vim.tbl_keys(self.cached_endpoints),
    timestamps = self.cache_timestamps,
    valid_all = self:is_valid(),
  }
end

-- Export the CacheManager class for OOP usage
return CacheManager
