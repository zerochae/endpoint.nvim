-- Logging utility for endpoint.nvim
---@class endpoint.utils.log
local M = {}

-- Check if debug mode is enabled
local function is_debug_enabled()
  return vim.g.endpoint_debug == true
end

-- Log info message (only in debug mode)
function M.info(message)
  if is_debug_enabled() then
    vim.notify(message, vim.log.levels.INFO)
  end
end

-- Log warning message (only in debug mode)
function M.warn(message)
  if is_debug_enabled() then
    vim.notify(message, vim.log.levels.WARN)
  end
end

-- Log error message (always shown)
function M.error(message)
  vim.notify(message, vim.log.levels.ERROR)
end

-- Log debug message with framework prefix
function M.framework_debug(message)
  if is_debug_enabled() then
    vim.notify("[Framework Debug] " .. message, vim.log.levels.INFO)
  end
end

-- Log general endpoint message
function M.endpoint(message, level)
  level = level or vim.log.levels.INFO
  vim.notify(message, level)
end

return M
