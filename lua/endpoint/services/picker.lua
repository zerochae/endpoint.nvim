local picker_manager = require "endpoint.picker.manager"
local state = require "endpoint.core.state"
local log = require "endpoint.utils.log"

local M = {}

local function get_config()
  local config = state.get_config()
  if not config then
    log.error "Configuration not found. Call setup() first."
    return nil
  end
  return config
end

function M.initialize()
  local config = get_config()
  if not config then
    return false
  end

  log.info "Initializing picker system..."
  local success = picker_manager.initialize(config)

  if success then
    log.info "Picker system initialized successfully"
  else
    log.error "Failed to initialize picker system"
  end

  return success
end

function M.get_current_picker()
  return picker_manager.get_current_picker()
end

function M.show_picker(method, opts)
  return picker_manager.show_picker(method, opts)
end

return M

