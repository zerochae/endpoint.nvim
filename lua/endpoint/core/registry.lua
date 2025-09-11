-- Framework registry for dynamic framework discovery and loading
local M = {}

-- Cache for loaded framework configs
local framework_configs = {}

-- Cache the config directory path to avoid repeated searches
local cached_config_dir = nil

-- Get all available framework names by scanning config directory
function M.get_available_frameworks()
  local frameworks = {}
  
  -- Use cached path if available
  if cached_config_dir and vim.fn.isdirectory(cached_config_dir) == 1 then
    local files = vim.split(vim.fn.glob(cached_config_dir .. "/*.lua"), "\n")
    for _, file in ipairs(files) do
      if file ~= "" then
        local name = vim.fn.fnamemodify(file, ":t:r")
        table.insert(frameworks, name)
      end
    end
    return frameworks
  end
  
  -- Find config directory using multiple strategies
  local config_dir = nil
  
  -- Strategy 1: Use runtimepath (most reliable in test environment)
  for _, rtp_path in ipairs(vim.opt.runtimepath:get()) do
    -- Convert to absolute path to handle directory changes
    local abs_rtp = vim.fn.fnamemodify(rtp_path, ":p")
    if abs_rtp:match("endpoint") then
      local candidate = abs_rtp .. "/lua/endpoint/framework/config"
      if vim.fn.isdirectory(candidate) == 1 then
        config_dir = candidate
        break
      end
    end
  end
  
  if not config_dir then
    -- Strategy 2: Use package.path with absolute paths
    for path_part in package.path:gmatch("[^;]+") do
      local base_path = path_part:match("^(.*)/lua/%?%.lua$") or path_part:match("^(.*)/lua/%?/init%.lua$")
      if base_path then
        -- Convert to absolute path
        local abs_base = vim.fn.fnamemodify(base_path, ":p")
        local candidate = abs_base .. "/lua/endpoint/framework/config"
        if vim.fn.isdirectory(candidate) == 1 then
          config_dir = candidate
          break
        end
      end
    end
  end
  
  if not config_dir then
    -- Strategy 3: Try common absolute paths
    local common_paths = {
      "/Users/kwon-gray/Dev/nvim-project/endpoint.nvim/lua/endpoint/framework/config",
      "/Users/kwon-gray/dev/nvim-project/endpoint.nvim/lua/endpoint/framework/config"
    }
    for _, path in ipairs(common_paths) do
      if vim.fn.isdirectory(path) == 1 then
        config_dir = path
        break
      end
    end
  end
  
  if not config_dir then
    return frameworks
  end
  
  -- Cache the found directory
  cached_config_dir = config_dir
  
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
