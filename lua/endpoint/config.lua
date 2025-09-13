-- Simplified Configuration (Function-based)
local M = {}

-- Default configuration
local default_config = {
  -- Cache configuration
  cache_mode = "none", -- "none", "session", "persistent"

  -- Picker configuration
  picker = "telescope", -- "telescope", "vim_ui_select", "snacks"
  picker_opts = {}, -- Additional options passed to picker (Telescope only)

  -- UI configuration
  ui = {
    show_icons = true,
    show_method = true,
    method_icons = {
      GET = "📥",
      POST = "📤",
      PUT = "✏️",
      DELETE = "🗑️",
      PATCH = "🔧",
    },
    method_colors = {
      GET = "TelescopeResultsNumber",
      POST = "TelescopeResultsConstant",
      PUT = "TelescopeResultsKeyword",
      DELETE = "TelescopeResultsSpecialChar",
      PATCH = "TelescopeResultsFunction",
    },
  },

  -- Framework-specific configuration
  frameworks = {
    rails = {
      display_format = "smart", -- "action_only", "controller_action", "smart"
      show_action_annotation = true, -- Show [controller#action] annotations
    },
  },
}

local current_config = vim.deepcopy(default_config)

-- Set configuration
function M.setup(user_config)
  user_config = user_config or {}
  current_config = vim.tbl_deep_extend("force", current_config, user_config)

  -- Initialize cache with the configured mode
  local cache = require "endpoint.cache"
  cache.set_mode(current_config.cache_mode)

  -- Initialize scanner
  local scanner = require "endpoint.scanner"
  scanner.setup(current_config)
end

-- Get current configuration
---@return table
function M.get()
  return current_config
end

-- Get specific config value
---@param key string
---@return any
function M.get_value(key)
  return current_config[key]
end

-- Set specific config value
---@param key string
---@param value any
function M.set_value(key, value)
  current_config[key] = value
end

-- Reset to defaults
function M.reset()
  current_config = vim.deepcopy(default_config)
end

return M
