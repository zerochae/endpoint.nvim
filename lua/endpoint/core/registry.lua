-- Framework registry for dynamic framework discovery and loading
local M = {}

-- Cache for loaded framework configs
local framework_configs = {}

-- Get all available framework names by scanning config directory
function M.get_available_frameworks()
  local frameworks = {}
  -- Get the current file's directory and construct the config path relative to it
  local current_file_dir = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h")
  local config_dir = current_file_dir .. "/../framework/config"
  local files = vim.split(vim.fn.glob(config_dir .. "/*.lua"), "\n")

  for _, file in ipairs(files) do
    if file ~= "" then
      local name = vim.fn.fnamemodify(file, ":t:r")
      table.insert(frameworks, name)
    end
  end

  return frameworks
end

-- Load framework configuration dynamically
function M.get_framework_config(framework_name)
  if framework_configs[framework_name] then
    return framework_configs[framework_name]
  end

  local ok, config = pcall(require, "endpoint.framework.config." .. framework_name)
  if ok then
    framework_configs[framework_name] = config
    return config
  end

  return nil
end

-- Build frameworks table dynamically
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

return M
