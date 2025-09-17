local config = require "endpoint.config"
local EndpointManager = require "endpoint.core.EndpointManager"

local endpoint_manager = EndpointManager:new()

local M = {}

-- Setup function
---@param user_config? table
function M.setup(user_config)
  endpoint_manager:setup(user_config)
end

-- Main function to find and show endpoints
---@param opts? table
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
---@return table
function M.get_config()
  return config.get()
end

-- Get framework information
---@return table[] framework_info_list List of framework information
function M.get_framework_info()
  return endpoint_manager:get_framework_info()
end

-- Detect frameworks in current project
---@return Framework[] detected_frameworks List of detected framework instances
function M.detect_frameworks()
  return endpoint_manager:detect_project_frameworks()
end

-- Scan with specific framework
---@param framework_name string The framework name to use
---@param opts? table Optional scan configuration
function M.scan_with_framework(framework_name, opts)
  return endpoint_manager:scan_with_framework(framework_name, opts)
end


return M
