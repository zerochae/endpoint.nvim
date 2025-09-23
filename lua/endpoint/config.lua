-- Configuration with backward compatibility
local M = {}

-- New improved configuration structure
local default_config = {
  -- Picker configuration
  picker = {
    type = "telescope", -- "telescope", "vim_ui_select", "snacks"
    options = {
      telescope = {}, -- Telescope-specific options
      snacks = {}, -- Snacks-specific options
      vim_ui_select = {}, -- vim.ui.select-specific options
    },
  },

  -- UI configuration (new structure)
  ui = {
    show_icons = true,
    show_method = true,
    methods = {
      GET = { icon = "📥", color = "TelescopeResultsNumber" },
      POST = { icon = "📤", color = "TelescopeResultsConstant" },
      PUT = { icon = "✏️", color = "TelescopeResultsKeyword" },
      DELETE = { icon = "🗑️", color = "TelescopeResultsSpecialChar" },
      PATCH = { icon = "🔧", color = "TelescopeResultsFunction" },
      ROUTE = { icon = "🔗", color = "TelescopeResultsIdentifier" },
    },
  },

  -- Cache configuration
  cache = {
    mode = "session", -- "none", "session", "persistent"
  },

  -- Framework-specific configuration
  frameworks = {
    rails = {
      display_format = "smart", -- "action_only", "controller_action", "smart"
      show_action_annotation = true, -- Show [controller#action] annotations
    },
    django = {
      url_param_format = "%v:%t", -- Content template: %v=variable name, %t=type
      url_param_fallback = "%v", -- Fallback content when type is unavailable (regex patterns)
      url_param_brackets = "{}", -- Bracket style: "{}", "<>", "[]", "()", or custom like "⟨⟩"
      -- Examples:
      --   "%v:%t" + "{}" -> {pk:int}
      --   "%t:%v" + "<>" -> <int:pk>
      --   "%v" + "[]" -> [pk]
    },
  },

  -- Legacy fields for backward compatibility (will be removed in v2.0)
  picker_opts = {}, -- @deprecated: use picker.options instead
}

local current_config = vim.deepcopy(default_config)

-- Helper function to show deprecation warnings
local function warn_deprecated(old_key, new_key, version)
  vim.notify_once(
    string.format(
      "[endpoint.nvim] DEPRECATED: '%s' is deprecated and will be removed in %s. Please use '%s' instead.",
      old_key,
      version or "v2.0",
      new_key
    ),
    vim.log.levels.WARN,
    { title = "endpoint.nvim" }
  )
end

-- Migrate old configuration to new structure
local function migrate_config(config)
  local migrated = vim.deepcopy(config)


  -- Handle picker + picker_opts -> picker.type + picker.options migration
  if config.picker and type(config.picker) == "string" then
    -- Old format: picker is a string, convert to new format
    if config.picker_opts then
      warn_deprecated("picker_opts", "picker.options", "v2.0")
    end

    migrated.picker = {
      type = config.picker,
      options = config.picker_opts or {},
    }
  elseif config.picker_opts and not (config.picker and type(config.picker) == "table") then
    -- Handle case where only picker_opts is provided with default picker
    warn_deprecated("picker_opts", "picker.options", "v2.0")
    migrated.picker = migrated.picker or {}
    migrated.picker.options = config.picker_opts
  end

  -- Handle method_icons + method_colors -> ui.methods migration
  if config.ui then
    if config.ui.method_icons or config.ui.method_colors then
      warn_deprecated("ui.method_icons and ui.method_colors", "ui.methods", "v2.0")

      migrated.ui = migrated.ui or {}
      migrated.ui.methods = migrated.ui.methods or {}

      -- Migrate icons and colors to combined structure
      local icons = config.ui.method_icons or {}
      local colors = config.ui.method_colors or {}

      for method, icon in pairs(icons) do
        migrated.ui.methods[method] = migrated.ui.methods[method] or {}
        migrated.ui.methods[method].icon = icon
      end

      for method, color in pairs(colors) do
        migrated.ui.methods[method] = migrated.ui.methods[method] or {}
        migrated.ui.methods[method].color = color
      end

      -- Remove old keys
      migrated.ui.method_icons = nil
      migrated.ui.method_colors = nil
    end
  end

  -- Clean up legacy keys
  migrated.picker_opts = nil

  return migrated
end

-- Set configuration
function M.setup(user_config)
  user_config = user_config or {}

  -- Migrate old configuration format to new format
  local migrated_config = migrate_config(user_config)

  -- Merge with default config
  current_config = vim.tbl_deep_extend("force", default_config, migrated_config)
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
