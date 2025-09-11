-- Framework manager
-- Handles loading and using framework-specific implementations

local detector = require "endpoint.framework.detector"

local M = {}

-- Cache for loaded frameworks
local framework_cache = {}

-- Load a framework implementation
local function load_framework(framework_name)
  if framework_cache[framework_name] then
    return framework_cache[framework_name]
  end

  local ok, framework = pcall(require, "endpoint.framework.registry." .. framework_name)
  if not ok then
    vim.notify("Failed to load framework: " .. framework_name .. " - " .. framework, vim.log.levels.ERROR)
    return nil
  end

  framework_cache[framework_name] = framework
  return framework
end

-- Get the current framework implementation based on detection
function M.get_current_framework(config)
  local framework_name, framework_config = detector.get_current_framework_config(config)

  local framework = load_framework(framework_name)
  if not framework then
    return nil
  end

  return framework, framework_name, framework_config
end

-- Get grep command using current framework
function M.get_grep_cmd(method, config)
  local framework, framework_name, framework_config = M.get_current_framework(config)
  if not framework then
    error "No framework implementation available"
  end

  if config.debug then
    vim.notify("Using " .. framework_name .. " framework for method: " .. method, vim.log.levels.INFO)
  end

  return framework:get_grep_cmd(method, framework_config)
end

-- Parse line using current framework
function M.parse_line(line, method, config)
  local framework, _, _ = M.get_current_framework(config)
  if not framework then
    return nil
  end

  return framework:parse_line(line, method)
end

-- Check if current framework can handle a line
function M.can_handle_line(line, config)
  local framework = M.get_current_framework(config)
  if not framework then
    return false
  end

  return framework:can_handle(line)
end

-- Get file patterns for current framework
function M.get_file_patterns(config)
  local framework, _, framework_config = M.get_current_framework(config)
  if not framework then
    return { "**/*" } -- Fallback
  end

  -- First try to get from framework_config, then from framework implementation
  if framework_config and framework_config.file_patterns then
    return framework_config.file_patterns
  end

  return framework:get_file_patterns()
end

-- Get exclude patterns for current framework
function M.get_exclude_patterns(config)
  local framework, _, framework_config = M.get_current_framework(config)
  if not framework then
    return {} -- Fallback
  end

  -- First try to get from framework_config, then from framework implementation
  if framework_config and framework_config.exclude_patterns then
    return framework_config.exclude_patterns
  end

  return framework:get_exclude_patterns()
end

-- Get base path using current framework
function M.get_base_path(file_path, line_number, config)
  local framework = M.get_current_framework(config)
  if not framework then
    return ""
  end

  return framework:get_base_path(file_path, line_number)
end

-- Get method patterns for current framework
function M.get_patterns(config)
  local framework, _, framework_config = M.get_current_framework(config)
  if not framework then
    return {}
  end

  -- First try to get from framework_config, then from framework implementation
  if framework_config and framework_config.patterns then
    return framework_config.patterns
  end

  return framework:get_patterns()
end

-- Get current framework name
function M.get_current_framework_name(config)
  local framework_name = detector.detect_framework(config)
  return framework_name
end

-- Validate that a framework implements required interface
function M.validate_framework(framework, framework_name)
  local required_methods = {
    "get_grep_cmd",
    "parse_line",
    "get_patterns",
    "can_handle",
    "get_file_patterns",
    "get_exclude_patterns",
    "get_base_path",
  }

  for _, method_name in ipairs(required_methods) do
    if not framework[method_name] or type(framework[method_name]) ~= "function" then
      vim.notify("Framework " .. framework_name .. " missing required method: " .. method_name, vim.log.levels.ERROR)
      return false
    end
  end

  return true
end

-- List all available frameworks
function M.list_available_frameworks()
  local frameworks = {}

  -- Check for framework files in the registry directory
  local framework_files = vim.fn.glob(vim.fn.stdpath "config" .. "/lua/endpoint/framework/registry/*.lua", false, true)

  for _, file_path in ipairs(framework_files) do
    local filename = vim.fn.fnamemodify(file_path, ":t:r")
    if filename ~= "base" then -- Skip the base interface file
      table.insert(frameworks, filename)
    end
  end

  return frameworks
end

return M
