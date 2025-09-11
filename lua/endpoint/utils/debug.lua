-- Debug utility module
local M = {}

-- Global debug log function
-- @param message string: Debug message
-- @param level number: vim.log.levels (optional, defaults to INFO)
function M.debug_log(message, level)
  local session = require("endpoint.core.session")
  local config = session.get_config()
  
  if config and config.debug then
    vim.notify("DEBUG: " .. message, level or vim.log.levels.INFO)
  end
end

-- Log with INFO level
-- @param message string: Debug message
function M.info(message)
  M.debug_log(message, vim.log.levels.INFO)
end

-- Log with WARN level
-- @param message string: Warning message
function M.warn(message)
  M.debug_log(message, vim.log.levels.WARN)
end

-- Log with ERROR level
-- @param message string: Error message
function M.error(message)
  M.debug_log(message, vim.log.levels.ERROR)
end

return M