local framework_manager = require "endpoint.framework.manager"
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

function M.get_current_framework()
  local config = get_config()
  if not config then
    return nil
  end

  log.info "Getting current framework..."
  local framework, name, framework_config = framework_manager.get_current_framework(config)

  if framework then
    log.info("Using framework: " .. (name or "unknown"))
  else
    log.warn "No framework detected"
  end

  return framework, name, framework_config
end

function M.get_grep_cmd(method)
  local config = get_config()
  if not config then
    return nil
  end

  log.info("Getting grep command for method: " .. method)
  return framework_manager.get_grep_cmd(method, config)
end

function M.parse_line(line, method)
  local config = get_config()
  if not config then
    return nil
  end

  return framework_manager.parse_line(line, method, config)
end

function M.can_handle_line(line)
  local config = get_config()
  if not config then
    return false
  end

  return framework_manager.can_handle_line(line, config)
end

function M.get_file_patterns()
  local config = get_config()
  if not config then
    return {}
  end

  return framework_manager.get_file_patterns(config)
end

function M.get_exclude_patterns()
  local config = get_config()
  if not config then
    return {}
  end

  return framework_manager.get_exclude_patterns(config)
end

function M.get_base_path(file_path, line_number)
  local config = get_config()
  if not config then
    return ""
  end

  return framework_manager.get_base_path(file_path, line_number, config)
end

function M.get_patterns()
  local config = get_config()
  if not config then
    return {}
  end

  return framework_manager.get_patterns(config)
end

function M.get_current_framework_name()
  local config = get_config()
  if not config then
    return nil
  end

  local name = framework_manager.get_current_framework_name(config)
  log.info("Current framework: " .. (name or "none"))
  return name
end

return M

