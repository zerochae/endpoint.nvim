local M = {
  prompt_title = "endpoint finder",
  cache_mode = "persistent", -- Cache mode: "session" (valid until nvim closes) or "persistent" (file-based cache)
  debug = false, -- Enable debug logging

  -- Framework detection
  framework = "auto", -- "auto" for auto-detection, or specify: "spring", "nestjs", "django", "rails", "express"
  framework_paths = {}, -- Path-specific framework overrides: { ["/path/to/project"] = "spring" }

  -- Cache mode configuration
  cache_mode_paths = {}, -- Path-specific cache mode overrides: { ["/path/to/project"] = "persistent" }

  -- Alternative: Unified project configuration (can use instead of above)
  -- project_paths = {
  --   ["/path/to/project"] = {
  --     framework = "spring",
  --     cache_mode = "persistent",
  --   }
  -- }

  -- Backward compatibility - will be overridden by framework detection
  file_patterns = { "**/*.java" }, -- Fallback if detection fails
  exclude_patterns = { "**/target/**", "**/build/**" }, -- Fallback if detection fails
  rg_additional_args = "", -- Additional ripgrep arguments

  -- Picker configuration
  picker = "telescope", -- "telescope", "snacks", "vim_ui_select" (fallback to vim_ui_select if not available)
  picker_opts = {}, -- Additional options to pass to the selected picker

  -- UI customization
  ui = {
    show_icons = false, -- Show method icons
    show_method = true, -- Show method text (GET, POST, PUT, DELETE)
    use_nerd_font = false, -- Use nerd font glyphs instead of emojis
    method_colors = {
      GET = "TelescopeResultsNumber", -- Default: Green-ish
      POST = "TelescopeResultsConstant", -- Default: Blue-ish
      PUT = "TelescopeResultsKeyword", -- Default: Orange-ish
      DELETE = "TelescopeResultsSpecialChar", -- Default: Red-ish
      PATCH = "TelescopeResultsFunction", -- Default: Purple-ish
    },
    method_icons = {
      emoji = {
        GET = "📥",
        POST = "📤",
        PUT = "✏️",
        DELETE = "🗑️",
        PATCH = "🔧",
      },
      nerd_font = {
        GET = "", -- download icon
        POST = "", -- upload icon
        PUT = "", -- edit icon
        DELETE = "", -- trash icon
        PATCH = "", -- wrench icon
      },
    },
    -- Cache status UI icons (customizable)
    cache_status_icons = {
      emoji = {
        title = "🚀",
        project = "📁",
        stats = "📈",
        cache_files = "💾",
        tree = "🌳",
        directory = "📁",
        file = "📄",
        endpoint = "🔗",
        success = "✅",
        error = "❌",
        empty = "🌵",
        arrow = "➤",
      },
      nerd_font = {
        title = "",
        project = "",
        stats = "",
        cache_files = "",
        tree = "",
        directory = "",
        file = "",
        endpoint = "",
        success = "",
        error = "",
        empty = "",
        arrow = "",
      },
    },
    -- Cache status UI syntax highlighting
    cache_status_highlight = {
      title = "Special",
      border = "Comment",
      icon = "Identifier",
      success = "String",
      error = "ErrorMsg",
      key = "Keyword",
      tree_dir = "Directory",
      tree_file = "Type",
      tree_method = "Function",
      tree_endpoint = "String",
    },
    -- Cache status window size options
    cache_status_window = {
      width = 80, -- Window width (number or "max" for maximum available width)
      height = "auto", -- Window height ("auto" for content height, number for fixed height, or "max" for maximum)
      center_align = false, -- Center align content (excluding tree view)
    },
  },
}

return M
