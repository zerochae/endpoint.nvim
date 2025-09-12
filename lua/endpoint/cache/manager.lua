local base_manager = require "endpoint.core.base_manager"

local M = base_manager.create_manager("cache", "none")

-- Cache implementations will be registered during setup
-- Temporary fallback: register immediately for compatibility
M.register("none", "endpoint.cache.registry.none")
M.register("session", "endpoint.cache.registry.session")
M.register("persistent", "endpoint.cache.registry.persistent")

local function get_cache_config()
  local ok, state = pcall(require, "endpoint.core.state")
  if ok then
    local config = state.get_config()
    if config then
      return {
        mode = config.cache_mode or "none",
      }
    end
  end

  local config_ok, default_config = pcall(require, "endpoint.core.config")
  if config_ok then
    return {
      mode = default_config.cache_mode or "none",
    }
  end

  return {
    mode = "none",
  }
end

function M.get_current()
  local cache_config = get_cache_config()
  return M.get(cache_config.mode)
end

function M.session()
  return M.get "session"
end

return M

