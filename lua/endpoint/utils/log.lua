-- Logging utility for endpoint.nvim
---@class endpoint.utils.log
local M = {}

-- Check if debug mode is enabled
---@return boolean
local function is_debug_enabled()
  return vim.g.endpoint_debug == true
end

-- Log info message (only in debug mode)
---@param message string The message to log
function M.info(message)
  if is_debug_enabled() then
    vim.notify(message, vim.log.levels.INFO)
  end
end

-- Log warning message (only in debug mode)
---@param message string The message to log
function M.warn(message)
  if is_debug_enabled() then
    vim.notify(message, vim.log.levels.WARN)
  end
end

-- Log error message (always shown)
---@param message string The message to log
function M.error(message)
  vim.notify(message, vim.log.levels.ERROR)
end

-- Log debug message with framework prefix
---@param message string The message to log
function M.framework_debug(message)
  if is_debug_enabled() then
    vim.notify("[Framework Debug] " .. message, vim.log.levels.INFO)
  end
end

-- Log general endpoint message
---@param message string The message to log
---@param level? number Log level (defaults to INFO)
function M.endpoint(message, level)
  level = level or vim.log.levels.INFO
  vim.notify(message, level)
end

return M