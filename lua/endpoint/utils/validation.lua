-- Input validation utilities
local M = {}

-- Validate cache configuration
function M.validate_cache_config(config)
  local errors = {}

  if config.cache_ttl and type(config.cache_ttl) ~= "number" then
    table.insert(errors, "cache_ttl must be a number")
  end

  if config.cache_mode and not vim.tbl_contains({ "session", "persistent" }, config.cache_mode) then
    table.insert(errors, "cache_mode must be 'session' or 'persistent'")
  end

  return errors
end

-- Validate UI configuration
function M.validate_ui_config(config)
  local errors = {}

  if not config.ui then
    return errors
  end

  if config.ui.method_colors then
    for method, color in pairs(config.ui.method_colors) do
      if type(color) ~= "string" then
        table.insert(errors, "method color for " .. method .. " must be a string")
      end
    end
  end

  if config.ui.show_icons ~= nil and type(config.ui.show_icons) ~= "boolean" then
    table.insert(errors, "show_icons must be a boolean")
  end

  if config.ui.show_method ~= nil and type(config.ui.show_method) ~= "boolean" then
    table.insert(errors, "show_method must be a boolean")
  end

  return errors
end

-- Validate framework configuration
function M.validate_framework_config(config, available_frameworks)
  local errors = {}

  if config.framework and type(config.framework) ~= "string" then
    table.insert(errors, "framework must be a string")
  end

  if config.framework_paths and type(config.framework_paths) ~= "table" then
    table.insert(errors, "framework_paths must be a table")
  end

  -- Validate supported frameworks
  local supported_frameworks = vim.deepcopy(available_frameworks)
  table.insert(supported_frameworks, "auto")

  if config.framework and not vim.tbl_contains(supported_frameworks, config.framework) then
    table.insert(
      errors,
      "Unsupported framework '" .. config.framework .. "'. Supported: " .. table.concat(supported_frameworks, ", ")
    )
  end

  return errors
end

-- Validate entire configuration
function M.validate_config(config, available_frameworks)
  local all_errors = {}

  -- Collect all validation errors
  local cache_errors = M.validate_cache_config(config)
  local ui_errors = M.validate_ui_config(config)
  local framework_errors = M.validate_framework_config(config, available_frameworks)

  vim.list_extend(all_errors, cache_errors)
  vim.list_extend(all_errors, ui_errors)
  vim.list_extend(all_errors, framework_errors)

  return all_errors
end

-- Report validation errors
function M.report_errors(errors)
  for _, error in ipairs(errors) do
    vim.notify("Warning: " .. error, vim.log.levels.WARN)
  end
end

return M
