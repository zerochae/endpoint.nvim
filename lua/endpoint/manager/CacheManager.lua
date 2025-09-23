---@class endpoint.CacheManager
local CacheManager = {}
CacheManager.__index = CacheManager

function CacheManager:new()
  local cache_instance = setmetatable({}, self)
  cache_instance.cached_endpoints = {}
  cache_instance.cache_timestamps = {}
  cache_instance.cache_mode = "session" -- Will be set by EndpointManager
  return cache_instance
end

function CacheManager:set_mode(mode)
  self.cache_mode = mode
end

function CacheManager:_get_cache_key(method)
  return method or "all"
end

function CacheManager:_get_cache_dir()
  return vim.fn.stdpath("cache") .. "/endpoint.nvim"
end

function CacheManager:_get_project_hash()
  -- Use current working directory name as simple project identifier
  return vim.fn.fnamemodify(vim.fn.getcwd(), ":t"):gsub("[^%w]", "_")
end

function CacheManager:_get_cache_file_path(method)
  local cache_dir = self:_get_cache_dir()
  local project_hash = self:_get_project_hash()
  local cache_key = self:_get_cache_key(method)

  -- Handle the case where method is nil (all endpoints)
  if not method or method == "" then
    return cache_dir .. "/" .. project_hash .. ".json"
  else
    return cache_dir .. "/" .. project_hash .. "_" .. cache_key .. ".json"
  end
end

function CacheManager:_ensure_cache_dir()
  local cache_dir = self:_get_cache_dir()
  if vim.fn.isdirectory(cache_dir) == 0 then
    vim.fn.mkdir(cache_dir, "p")
  end
end

function CacheManager:is_valid(method)
  if self.cache_mode == "persistent" then
    return self:_load_from_disk(method)
  else
    local cache_key = self:_get_cache_key(method)
    return self.cached_endpoints[cache_key] and #self.cached_endpoints[cache_key] > 0
  end
end

function CacheManager:get_endpoints(method)
  if self.cache_mode == "persistent" then
    local endpoints = self:_load_from_disk(method)
    return endpoints or {}
  else
    local cache_key = self:_get_cache_key(method)
    return self.cached_endpoints[cache_key] or {}
  end
end

function CacheManager:save_endpoints(endpoints, method)
  local cache_key = self:_get_cache_key(method)

  -- Always save to memory for session access
  self.cached_endpoints[cache_key] = endpoints
  self.cache_timestamps[cache_key] = vim.loop.hrtime()

  -- Also save to disk if persistent mode
  if self.cache_mode == "persistent" then
    self:_save_to_disk(endpoints, method)
  end
end

function CacheManager:_save_to_disk(endpoints, method)
  local success, err = pcall(function()
    self:_ensure_cache_dir()
    local file_path = self:_get_cache_file_path(method)
    local cache_data = {
      endpoints = endpoints,
      timestamp = os.time(),
      method = method,
    }
    local json_str = vim.json.encode(cache_data)
    local file = io.open(file_path, "w")
    if file then
      file:write(json_str)
      file:close()
    end
  end)

  if not success then
    vim.notify("Failed to save cache to disk: " .. (err or "unknown error"), vim.log.levels.WARN)
  end
end

function CacheManager:_load_from_disk(method)
  local success, result = pcall(function()
    local file_path = self:_get_cache_file_path(method)

    if vim.fn.filereadable(file_path) == 0 then
      return nil
    end

    local file = io.open(file_path, "r")
    if not file then
      return nil
    end

    local json_str = file:read("*a")
    file:close()

    if not json_str or json_str == "" then
      return nil
    end

    local cache_data = vim.json.decode(json_str)
    return cache_data.endpoints
  end)

  if success then
    return result
  else
    -- If loading fails, return nil (cache miss)
    return nil
  end
end

function CacheManager:clear()
  self.cached_endpoints = {}
  self.cache_timestamps = {}

  -- Also clear persistent cache files if in persistent mode
  if self.cache_mode == "persistent" then
    self:_clear_disk_cache()
  end
end

function CacheManager:_clear_disk_cache()
  local success, err = pcall(function()
    local cache_dir = self:_get_cache_dir()
    local project_hash = self:_get_project_hash()

    -- Remove all cache files for this project
    local pattern = cache_dir .. "/" .. project_hash .. "_*.json"
    local files = vim.split(vim.fn.glob(pattern), "\n")

    for _, file_path in ipairs(files) do
      if file_path ~= "" and vim.fn.filereadable(file_path) == 1 then
        os.remove(file_path)
      end
    end
  end)

  if not success then
    vim.notify("Failed to clear disk cache: " .. (err or "unknown error"), vim.log.levels.WARN)
  end
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
