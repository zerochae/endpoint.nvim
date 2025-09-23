local config = require "endpoint.config"
local EndpointManager = require "endpoint.manager.EndpointManager"

local endpoint_manager = EndpointManager:new()

local M = {}

-- Setup function
function M.setup(user_config)
  endpoint_manager:setup(user_config)
end

-- Main function to find and show endpoints
function M.find(opts)
  endpoint_manager:find(opts)
end

-- Force refresh (bypass cache)
function M.refresh()
  M.find { force_refresh = true }
end

-- Cache management
function M.clear_cache()
  endpoint_manager:clear_cache()
end

function M.show_cache_stats()
  endpoint_manager:show_cache_stats()
end

-- Get configuration
function M.get_config()
  return config.get()
end

-- Get framework information
function M.get_framework_info()
  return endpoint_manager:get_framework_info()
end

-- Detect frameworks in current project
function M.detect_frameworks()
  return endpoint_manager:detect_project_frameworks()
end

-- Scan with specific framework
function M.scan_with_framework(framework_name, opts)
  return endpoint_manager:scan_with_framework(framework_name, opts)
end

return M
