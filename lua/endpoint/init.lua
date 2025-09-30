local config = require "endpoint.config"
local Endpoint = require "endpoint.core.Endpoint"

local endpoint = Endpoint:new()

local M = {}

-- Setup function
function M.setup(user_config)
  endpoint:setup(user_config)
end

-- Main function to find and show endpoints
function M.find(opts)
  endpoint:find(opts)
end

-- Force refresh (bypass cache)
function M.refresh()
  M.find { force_refresh = true }
end

-- Cache management
function M.clear_cache()
  endpoint:clear_cache()
end

function M.show_cache_stats()
  endpoint:show_cache_stats()
end

-- Get configuration
function M.get_config()
  return config.get()
end

-- Get framework information
function M.get_framework_info()
  return endpoint:get_framework_info()
end

-- Detect frameworks in current project
function M.detect_frameworks()
  return endpoint:detect_project_frameworks()
end

-- Scan with specific framework
function M.scan_with_framework(framework_name, opts)
  return endpoint:scan_with_framework(framework_name, opts)
end

return M
