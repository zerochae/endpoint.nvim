-- Default picker configuration

local M = {
  -- Default picker to use (will fallback to vim_ui_select if not available)
  picker = "telescope",

  -- Additional options to pass to the selected picker
  picker_opts = {},

  -- Picker-specific default configurations
  telescope = {
    -- Telescope-specific options
    layout_strategy = "horizontal",
    layout_config = {
      preview_width = 0.6,
    },
    sorting_strategy = "ascending",
  },

  snacks = {
    -- Snacks-specific options
    layout = {
      preview = {
        width = 0.6,
      },
    },
  },

  vim_ui_select = {
    -- vim.ui.select-specific options
    kind = "endpoint",
  },
}

return M

