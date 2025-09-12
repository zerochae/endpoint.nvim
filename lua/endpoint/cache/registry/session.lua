-- Session cache - Memory-based caching for current session
local base = require "endpoint.cache.base"

local M = base.new {}

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

return M

