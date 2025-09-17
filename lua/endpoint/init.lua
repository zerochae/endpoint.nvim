local config = require "endpoint.config"
local FrameworkRegistry = require "endpoint.core.FrameworkRegistry"

-- Global framework registry instance
local framework_registry = nil

local M = {}

-- Available pickers
local pickers = {
  telescope = require "endpoint.pickers.telescope",
  vim_ui_select = require "endpoint.pickers.vim_ui_select",
  snacks = require "endpoint.pickers.snacks",
}

-- Setup function
---@param user_config? table
function M.setup(user_config)
  config.setup(user_config)

  -- Initialize framework registry and register all frameworks
  framework_registry = FrameworkRegistry:new()
  framework_registry:register_all_frameworks()
end

-- Main function to find and show endpoints
---@param opts? table
function M.find(opts)
  opts = opts or {}

  if not framework_registry then
    vim.notify("endpoint.nvim not initialized. Call setup() first.", vim.log.levels.ERROR)
    return
  end

  -- Scan for all endpoints using the new OOP structure
  local endpoints = framework_registry:scan_all_endpoints(opts)

  if #endpoints == 0 then
    vim.notify("No endpoints found", vim.log.levels.INFO)
    return
  end

  -- Get configured picker (support both new and old structure)
  local current_config = config.get()
  local picker_name = current_config.picker and current_config.picker.type or current_config.picker or "telescope"
  local picker = pickers[picker_name]

  if not picker then
    vim.notify("Picker '" .. picker_name .. "' not found, using vim_ui_select", vim.log.levels.WARN)
    picker = pickers.vim_ui_select
  end

  if not picker.is_available() then
    vim.notify("Picker '" .. picker_name .. "' not available, using vim_ui_select", vim.log.levels.WARN)
    picker = pickers.vim_ui_select
  end

  -- Show endpoints in picker
  -- Support both new and old config structure for backward compatibility
  local current_config = config.get()
  local picker_config = current_config.picker or {}

  -- Get picker options (new structure first, then fallback to old)
  local all_picker_opts = picker_config.options or current_config.picker_opts or {}
  local current_picker_opts = all_picker_opts[picker_name] or {}

  -- Handle user-provided picker_opts (maintain compatibility)
  local user_picker_opts = (opts.picker_opts and opts.picker_opts[picker_name]) or opts.picker_opts or {}
  local picker_opts = vim.tbl_deep_extend("force", current_picker_opts, user_picker_opts)
  picker.show(endpoints, picker_opts)
end

-- Convenience alias
M.find_endpoints = M.find

-- Cache management
function M.clear_cache()
  local cache = require "endpoint.cache"
  cache.clear()
  vim.notify("Cache cleared", vim.log.levels.INFO)
end

function M.show_cache_stats()
  local cache = require "endpoint.cache"
  local stats = cache.get_stats()
  local message = string.format("Cache: %d endpoints, valid: %s", stats.total_endpoints, stats.valid and "yes" or "no")
  vim.notify(message, vim.log.levels.INFO)
end

-- Force refresh (bypass cache)
function M.refresh()
  M.find { force_refresh = true }
end

-- Get configuration
---@return table
function M.get_config()
  return config.get()
end

-- Get framework registry for advanced usage
---@return FrameworkRegistry|nil framework_registry The framework registry instance
function M.get_framework_registry()
  return framework_registry
end

-- Get endpoint manager for advanced usage
---@return EndpointManager|nil endpoint_manager The endpoint manager instance
function M.get_endpoint_manager()
  return framework_registry and framework_registry:get_endpoint_manager() or nil
end

-- Get framework information
---@return table[] framework_info_list List of framework information
function M.get_framework_info()
  if not framework_registry then
    return {}
  end
  return framework_registry:get_framework_info()
end

-- Detect frameworks in current project
---@return Framework[] detected_frameworks List of detected framework instances
function M.detect_frameworks()
  if not framework_registry then
    return {}
  end
  return framework_registry:detect_project_frameworks()
end

-- Scan with specific framework
---@param framework_name string The framework name to use
---@param opts? table Optional scan configuration
function M.scan_with_framework(framework_name, opts)
  if not framework_registry then
    vim.notify("endpoint.nvim not initialized. Call setup() first.", vim.log.levels.ERROR)
    return {}
  end
  return framework_registry:scan_with_framework(framework_name, opts or {})
end

-- Expose internal modules for advanced usage (backward compatibility)
M._cache = require "endpoint.cache"
M._config = config
-- Legacy framework access (deprecated)
M._framework = {
  scan = function(opts)
    if not framework_registry then
      return {}
    end
    return framework_registry:scan_all_endpoints(opts)
  end
}

return M
