local manager = require "endpoint.detector.manager"
local log = require "endpoint.utils.log"

local function get_config()
  local ok, state = pcall(require, "endpoint.core.state")
  if ok then
    local config = state.get_config()
    if config then
      return config
    end
  end

  local config_ok, core = pcall(require, "endpoint.core")
  if config_ok and core.get_config then
    return core.get_config()
  end

  return nil
end

local M = {}

function M.detect_framework()
  local config = get_config()
  if not config then
    log.warn "No config available for framework detection"
    return nil
  end

  log.info "Detecting framework..."
  return manager.detect_by_type("framework", config)
end

function M.get_current_framework_config()
  local config = get_config()
  if not config then
    error "No config available"
  end

  local framework_name = manager.detect_by_type("framework", config)
  if not framework_name then
    error "No framework detected. Please specify a framework in your configuration."
  end

  local framework_manager = require "endpoint.framework.manager"
  local framework_config = framework_manager.get_framework_config(framework_name)
  return framework_name, framework_config
end

function M.detect_picker(picker_name)
  log.info("Detecting picker: " .. (picker_name or "unknown"))
  return manager.detect_by_type("picker", picker_name)
end

function M.get_available_pickers()
  return manager.detect_all_available "picker"
end

function M.resolve_picker(requested_picker)
  local picker_detector = manager.get "picker"
  if picker_detector then
    return picker_detector:resolve_picker(requested_picker)
  end
  return "vim_ui_select"
end

function M.is_valid_picker_name(picker_name)
  local picker_detector = manager.get "picker"
  if picker_detector then
    return picker_detector:is_valid_picker_name(picker_name)
  end
  return false
end

function M.get_supported_pickers()
  local picker_detector = manager.get "picker"
  if picker_detector then
    return picker_detector:get_supported_pickers()
  end
  return {}
end

return M

