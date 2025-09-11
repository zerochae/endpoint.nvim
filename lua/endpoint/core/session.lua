-- Session state management
local M = {}

-- Global state
local state = {}

-- Get current working directory
local function get_cwd()
  return vim.fn.getcwd()
end

-- Get project-specific cache mode
local function get_project_cache_mode(config)
  if not config or not config.cache_mode_paths then
    return config and config.cache_mode or "none"
  end

  local cwd = get_cwd()

  -- Check for exact matches first
  if config.cache_mode_paths[cwd] then
    return config.cache_mode_paths[cwd]
  end

  -- Check for parent directory matches
  for path, cache_mode in pairs(config.cache_mode_paths) do
    if cwd:find("^" .. vim.pesc(path)) then
      return cache_mode
    end
  end

  -- Return default cache mode
  return config.cache_mode or "none"
end

-- Get current config with project-specific overrides
function M.get_config()
  if not state.config then
    return nil
  end

  -- Create a copy of the config with project-specific cache mode
  local config = vim.deepcopy(state.config)
  config.cache_mode = get_project_cache_mode(state.config)

  return config
end

-- Set config
function M.set_config(config)
  state.config = config
end

-- Check if setup was called
function M.is_setup_complete()
  return vim.g.endpoint_setup_called == true
end

-- Mark setup as complete
function M.mark_setup_complete()
  vim.g.endpoint_setup_called = true
end

return M
