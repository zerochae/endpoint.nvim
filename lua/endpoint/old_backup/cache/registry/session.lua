-- Session cache - Memory-based caching for current session
local cache_base = require "endpoint.cache.base"

---@class CacheRegistrySession : endpoint.CacheBase
local M = {}
setmetatable(M, { __index = cache_base })
M.name = "session"

function M:is_cache_valid(key, config)
  local cache_config = self:get_cache_config()

  -- Override with provided config if available
  if config and config.cache_mode then
    cache_config.mode = config.cache_mode
  end

  local cache_timestamp = self:get_cache_timestamp()
  local cached_time = cache_timestamp[key]

  if cache_config.mode == "state" or cache_config.mode == "session" then
    return cached_time ~= nil
  end

  return false
end

function M:should_use_cache(key, config)
  return self:is_cache_valid(key, config)
end

-- State mode doesn't clear for real-time, only none mode does
function M:clear_for_realtime_mode()
  -- Do nothing in state mode
end

-- No file operations for state mode
function M:save_to_file()
  -- Do nothing in state mode
end

function M:load_from_file()
  -- Do nothing in state mode
end

-- Override cleanup methods to prevent data loss in session mode
function M:track_access(table_name, key)
  -- Do nothing in session mode - no cleanup needed
end

function M:cleanup_cache_by_size(cache_table, max_entries, name)
  -- Do nothing in session mode - keep all data
end

-- Get which methods have been scanned (for intelligent cache management)
function M:get_scanned_methods()
  local cache_timestamp = self:get_cache_timestamp()
  return vim.tbl_keys(cache_timestamp)
end

-- Check if specific methods need scanning
function M:get_missing_methods(required_methods)
  local scanned_methods = self:get_scanned_methods()
  
  local scanned_set = {}
  for _, method in ipairs(scanned_methods) do
    scanned_set[method] = true
  end
  
  local missing_methods = {}
  for _, method in ipairs(required_methods) do
    if not scanned_set[method] then
      table.insert(missing_methods, method)
    end
  end
  
  return missing_methods
end

return M
