-- Debug utility module
local M = {}

-- Get current config for debug setting
---@return boolean
local function should_log()
  local ok, state = pcall(require, "endpoint.core.state")
  if ok then
    local config = state.get_config()
    if config and config.debug ~= nil then
      return config.debug
    end
  end

  -- Fallback to core config
  local core_ok, core = pcall(require, "endpoint.core")
  if core_ok and core.get_config then
    local config = core.get_config()
    if config and config.debug ~= nil then
      return config.debug
    end
  end

  -- Final fallback - don't log by default
  return false
end

-- Global debug log function
---@param message string Debug message
---@param level number? vim.log.levels (optional, defaults to INFO)
function M.debug_log(message, level)
  if not should_log() then
    return
  end
  vim.notify("DEBUG: " .. message, level or vim.log.levels.INFO)
end

-- Log with INFO level
---@param message string Debug message
function M.info(message)
  M.debug_log(message, vim.log.levels.INFO)
end

-- Log with WARN level
---@param message string Warning message
function M.warn(message)
  M.debug_log(message, vim.log.levels.WARN)
end

-- Log with ERROR level
---@param message string Error message
function M.error(message)
  M.debug_log(message, vim.log.levels.ERROR)
end

-- Log with DEBUG level
---@param message string Debug message
function M.debug(message)
  M.debug_log(message, vim.log.levels.DEBUG)
end

return M
