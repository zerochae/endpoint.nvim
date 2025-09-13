-- Simplified Endpoint.nvim Main Entry Point (Function-based)
local config = require "endpoint.config"
local scanner = require "endpoint.scanner"

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
end

-- Main function to find and show endpoints
---@param method? string
---@param opts? table
function M.find_endpoints(method, opts)
  method = method or "ALL"
  opts = opts or {}

  -- Scan for endpoints
  local endpoints = scanner.scan(method, opts)

  if #endpoints == 0 then
    vim.notify("No endpoints found for method: " .. method, vim.log.levels.INFO)
    return
  end

  -- Get configured picker
  local picker_name = config.get_value "picker"
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
  local picker_opts = vim.tbl_extend("force", config.get_value "picker_opts", opts.picker_opts or {})
  picker.show(endpoints, picker_opts)
end

-- Convenience functions for specific methods
function M.find_all()
  M.find_endpoints "ALL"
end

function M.find_get()
  M.find_endpoints "GET"
end

function M.find_post()
  M.find_endpoints "POST"
end

function M.find_put()
  M.find_endpoints "PUT"
end

function M.find_delete()
  M.find_endpoints "DELETE"
end

function M.find_patch()
  M.find_endpoints "PATCH"
end

function M.find_route()
  M.find_endpoints "ROUTE"
end

-- Cache management
function M.clear_cache()
  scanner.clear_cache()
  vim.notify("Cache cleared", vim.log.levels.INFO)
end

function M.show_cache_stats()
  local stats = scanner.get_cache_stats()
  local lines = {
    "=== Endpoint Cache Statistics ===",
    "Mode: " .. stats.mode,
    "Find entries: " .. stats.find_entries,
    "Preview entries: " .. stats.preview_entries,
    "Cached methods: " .. table.concat(stats.timestamps, ", "),
  }

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

-- Force refresh (bypass cache)
---@param method? string
function M.refresh(method)
  M.find_endpoints(method, { force_refresh = true })
end

-- Get configuration
---@return table
function M.get_config()
  return config.get()
end

-- Expose internal modules for advanced usage
M._cache = require "endpoint.cache"
M._scanner = scanner
M._config = config

return M
