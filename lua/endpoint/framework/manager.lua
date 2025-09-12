local base_manager = require "endpoint.core.base_manager"
local detector = require "endpoint.services.detector"

---@class endpoint.FrameworkManagerImpl
---@field register fun(type: string, module_path: string)
---@field get fun(type?: string): any

---@type endpoint.FrameworkManagerImpl
local M = base_manager.create_manager("framework", "auto")

-- Framework implementations will be registered during setup
-- Temporary fallback: register immediately for compatibility
M.register("spring", "endpoint.framework.registry.spring")
M.register("nestjs", "endpoint.framework.registry.nestjs")
M.register("fastapi", "endpoint.framework.registry.fastapi")
M.register("symfony", "endpoint.framework.registry.symfony")

-- Framework config management (from old registry.lua)
local framework_configs = {}
local cached_config_dir = nil

local function find_config_directory()
  if cached_config_dir and vim.fn.isdirectory(cached_config_dir) == 1 then
    return cached_config_dir
  end

  for _, rtp_path in ipairs(vim.opt.runtimepath:get()) do
    local abs_rtp = vim.fn.fnamemodify(rtp_path, ":p")
    if abs_rtp:match "endpoint" then
      local candidate = abs_rtp .. "/lua/endpoint/framework/config"
      if vim.fn.isdirectory(candidate) == 1 then
        cached_config_dir = candidate
        return candidate
      end
    end
  end

  for path_part in package.path:gmatch "[^;]+" do
    local base_path = path_part:match "^(.*)/lua/%?%.lua$" or path_part:match "^(.*)/lua/%?/init%.lua$"
    if base_path then
      local abs_base = vim.fn.fnamemodify(base_path, ":p")
      local candidate = abs_base .. "/lua/endpoint/framework/config"
      if vim.fn.isdirectory(candidate) == 1 then
        cached_config_dir = candidate
        return candidate
      end
    end
  end

  return nil
end

function M.get_available_frameworks()
  local config_dir = find_config_directory()
  if not config_dir then
    return {}
  end

  local frameworks = {}
  local files = vim.split(vim.fn.glob(config_dir .. "/*.lua"), "\n")

  for _, file in ipairs(files) do
    if file ~= "" then
      local name = vim.fn.fnamemodify(file, ":t:r")
      table.insert(frameworks, name)
    end
  end

  return frameworks
end

function M.get_framework_config(framework_name)
  if not framework_name or type(framework_name) ~= "string" then
    return nil
  end

  if framework_configs[framework_name] then
    return framework_configs[framework_name]
  end

  local ok, config = pcall(require, "endpoint.framework.config." .. framework_name)
  if ok and config then
    framework_configs[framework_name] = config
    return config
  end

  return nil
end

function M.build_frameworks_config()
  local frameworks = {}
  local available = M.get_available_frameworks()

  for _, framework_name in ipairs(available) do
    local config = M.get_framework_config(framework_name)
    if config then
      frameworks[framework_name] = config
    end
  end

  return frameworks
end

-- Override clear_cache to also clear config cache
local base_clear_cache = M.clear_cache
function M.clear_cache()
  base_clear_cache()
  framework_configs = {}
  cached_config_dir = nil
end

-- Framework management methods
function M.set_framework_cache(framework_name, framework)
  M.instances[framework_name] = framework
end

function M.get_current_framework(config)
  local framework_name, framework_config = detector.get_current_framework_config()

  local framework = M.get(framework_name)
  if not framework then
    return nil
  end

  return framework, framework_name, framework_config
end

function M.get_grep_cmd(method, config)
  local framework, framework_name, framework_config = M.get_current_framework(config)
  if not framework then
    error "No framework implementation available"
  end

  local log = require "endpoint.utils.log"
  log.info("Using " .. framework_name .. " framework for method: " .. method)

  return framework:get_grep_cmd(method, framework_config)
end

function M.parse_line(line, method, config)
  local framework, _, _ = M.get_current_framework(config)
  if not framework then
    return nil
  end

  return framework:parse_line(line, method)
end

function M.can_handle_line(line, config)
  local framework = M.get_current_framework(config)
  if not framework then
    return false
  end

  return framework:can_handle(line)
end

function M.get_file_patterns(config)
  local framework, _, framework_config = M.get_current_framework(config)
  if not framework then
    return { "**/*" }
  end
  if framework_config and framework_config.file_patterns then
    return framework_config.file_patterns
  end

  return framework:get_file_patterns()
end

function M.get_exclude_patterns(config)
  local framework, _, framework_config = M.get_current_framework(config)
  if not framework then
    return {}
  end
  if framework_config and framework_config.exclude_patterns then
    return framework_config.exclude_patterns
  end

  return framework:get_exclude_patterns()
end

function M.get_base_path(file_path, line_number, config)
  local framework = M.get_current_framework(config)
  if not framework then
    return ""
  end

  return framework:get_base_path(file_path, line_number)
end

function M.get_patterns(config)
  local framework, _, framework_config = M.get_current_framework(config)
  if not framework then
    return {}
  end
  if framework_config and framework_config.patterns then
    return framework_config.patterns
  end

  return framework:get_patterns()
end

function M.get_current_framework_name(config)
  local framework_name = detector.detect_framework()
  return framework_name
end

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

function M.list_available_frameworks()
  return M.get_available_types()
end

return M
