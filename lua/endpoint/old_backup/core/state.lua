local M = {}

---@type { config?: endpoint.Config }
local state = {}

---@return string
local function get_cwd()
  return vim.fn.getcwd()
end
---@param config endpoint.Config?
---@return string
local function get_project_cache_mode(config)
  if not config or not config.cache_mode_paths then
    return config and config.cache_mode or "none"
  end

  local cwd = get_cwd()

  if config.cache_mode_paths[cwd] then
    return config.cache_mode_paths[cwd]
  end

  for path, cache_mode in pairs(config.cache_mode_paths) do
    if cwd:find("^" .. vim.pesc(path)) then
      return cache_mode
    end
  end

  return config.cache_mode or "none"
end

---@return endpoint.Config?
function M.get_config()
  if not state.config then
    return nil
  end

  local config = vim.deepcopy(state.config)
  local cache_mode = get_project_cache_mode(state.config)
  config.cache_mode = cache_mode

  return config
end

---@param config endpoint.Config
function M.set_config(config)
  state.config = config
end

---@return boolean
function M.is_setup_complete()
  return vim.g.endpoint_setup_called == true
end

function M.mark_setup_complete()
  vim.g.endpoint_setup_called = true
end

return M
