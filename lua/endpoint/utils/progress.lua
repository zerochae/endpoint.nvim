-- Progress notification utility for endpoint.nvim
-- Supports fidget.nvim integration with vim.notify fallback
---@class endpoint.utils.progress
local M = {}

local config = require "endpoint.config"

---@class ProgressHandle
---@field title string
---@field message string
---@field percentage number|nil
---@field _fidget_handle any|nil
---@field _provider string

---Check if fidget.nvim is available
---@return boolean
local function has_fidget()
  local ok, fidget = pcall(require, "fidget")
  return ok and fidget.progress ~= nil
end

---Get the progress provider based on config
---@return string "fidget"|"notify"
local function get_provider()
  local progress_config = config.get().progress or {}
  local provider = progress_config.provider or "auto"

  if provider == "fidget" then
    return has_fidget() and "fidget" or "notify"
  elseif provider == "notify" then
    return "notify"
  else -- auto
    return has_fidget() and "fidget" or "notify"
  end
end

---Check if progress is enabled
---@return boolean
local function is_enabled()
  local progress_config = config.get().progress or {}
  return progress_config.enabled ~= false
end

---Create a new progress handle
---@param title string Title for the progress notification
---@param message string|nil Initial message
---@return ProgressHandle|nil
function M.create(title, message)
  if not is_enabled() then
    return nil
  end

  local provider = get_provider()

  ---@type ProgressHandle
  local handle = {
    title = title,
    message = message or "",
    percentage = nil,
    _provider = provider,
    _fidget_handle = nil,
  }

  if provider == "fidget" then
    local fidget = require "fidget"
    handle._fidget_handle = fidget.progress.handle.create {
      title = title,
      message = message,
      lsp_client = { name = "endpoint.nvim" },
      percentage = 0,
    }
  end

  return handle
end

---Update progress
---@param handle ProgressHandle|nil
---@param message string
---@param percentage number|nil 0-100
function M.update(handle, message, percentage)
  if not handle then
    return
  end

  handle.message = message
  handle.percentage = percentage

  if handle._provider == "fidget" and handle._fidget_handle then
    handle._fidget_handle:report {
      message = message,
      percentage = percentage,
    }
  end
  -- For notify provider, we don't show intermediate updates to avoid spam
end

---Finish progress (success)
---@param handle ProgressHandle|nil
---@param message string|nil Final message
function M.finish(handle, message)
  if not handle then
    return
  end

  local final_message = message or handle.message

  if handle._provider == "fidget" and handle._fidget_handle then
    handle._fidget_handle:report {
      message = final_message,
      percentage = 100,
    }
    handle._fidget_handle:finish()
  else
    -- For notify provider, show final result
    vim.schedule(function()
      vim.notify(
        string.format("[endpoint.nvim] %s: %s", handle.title, final_message),
        vim.log.levels.INFO
      )
    end)
  end
end

---Cancel progress
---@param handle ProgressHandle|nil
---@param message string|nil Cancel message
function M.cancel(handle, message)
  if not handle then
    return
  end

  if handle._provider == "fidget" and handle._fidget_handle then
    handle._fidget_handle:report {
      message = message or "Cancelled",
    }
    handle._fidget_handle:cancel()
  end
end

return M
