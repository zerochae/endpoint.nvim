-- Simplified Configuration (Function-based)
local M = {}

-- Default configuration
local default_config = {
  cache_mode = "session", -- "none", "session", "persistent"
  debug = false,
  picker = "telescope", -- "telescope", "vim_ui_select", "snacks"
  picker_opts = {},
  methods = { "GET", "POST", "PUT", "DELETE", "PATCH" },
  rg_additional_args = "",
  ui = {
    method_colors = {
      GET = "TelescopeResultsNumber",
      POST = "TelescopeResultsConstant",
      PUT = "TelescopeResultsKeyword",
      DELETE = "TelescopeResultsSpecialChar",
      PATCH = "TelescopeResultsFunction",
    },
    method_icons = {
      GET = "📥",
      POST = "📤",
      PUT = "✏️",
      DELETE = "🗑️",
      PATCH = "🔧",
    },
    show_icons = true,
    show_method = true,
  },
}

local current_config = vim.deepcopy(default_config)

-- Set configuration
function M.setup(user_config)
  user_config = user_config or {}
  current_config = vim.tbl_deep_extend("force", current_config, user_config)
  
  -- Initialize cache with the configured mode
  local cache = require("endpoint.cache")
  cache.set_mode(current_config.cache_mode)
  
  -- Initialize scanner
  local scanner = require("endpoint.scanner")
  scanner.setup(current_config)
end

-- Get current configuration
function M.get()
  return current_config
end

-- Get specific config value
function M.get_value(key)
  return current_config[key]
end

-- Set specific config value
function M.set_value(key, value)
  current_config[key] = value
end

-- Reset to defaults
function M.reset()
  current_config = vim.deepcopy(default_config)
end

return M