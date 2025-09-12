-- None cache - Real-time mode with no caching
local cache_base = require "endpoint.cache.base"

---@class CacheRegistryNone : endpoint.CacheBase
local M = {}
setmetatable(M, { __index = cache_base })
M.name = "none"

-- For cache_mode = "none", never use cache - always scan fresh
function M:is_cache_valid(key, config)
  return false
end

function M:should_use_cache(key, config)
  return false
end

-- Clear tables for real-time mode (used when cache_mode = "none")
function M:clear_for_realtime_mode()
  local cache_config = self:get_cache_config()
  if cache_config.mode == "none" then
    local find_table = self:get_find_table()
    local preview_table = self:get_preview_table()
    for k in pairs(find_table) do
      find_table[k] = nil
    end
    for k in pairs(preview_table) do
      preview_table[k] = nil
    end
  end
end

-- No-op for none mode
function M:save_to_file()
  -- Do nothing in none mode
end

function M:load_from_file()
  -- Do nothing in none mode
end

-- For none mode, always return all methods as missing since we never cache
function M:get_missing_methods(required_methods)
  return required_methods or {}
end

function M:get_scanned_methods()
  return {}
end

return M
