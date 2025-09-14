# Advanced Configuration

This page covers detailed configuration options for endpoint.nvim.

## Picker Configuration

### Telescope Picker

```lua
require("endpoint").setup({
  picker = "telescope",
  picker_opts = {
    telescope = {
      theme = "dropdown",
      previewer = false,
      layout_config = { 
        width = 0.8,
        height = 0.6 
      },
      sorting_strategy = "ascending",
      layout_strategy = "center",
    }
  }
})
```

**Features:**
- Rich fuzzy search interface
- File preview with syntax highlighting
- Full Telescope keybinding support
- Customizable themes and layouts

### Snacks Picker

```lua
require("endpoint").setup({
  picker = "snacks",
  picker_opts = {
    snacks = {
      prompt = "Find Endpoints ",
      matcher = { fuzzy = true, smartcase = true },
      preview = "file", -- "file", "none"
      layout = { width = 0.8, height = 0.6 }
    }
  }
})
```

**Features:**
- Modern picker interface
- File preview with precise line highlighting
- Fuzzy matching with file position patterns
- Clean, fast interface

### vim.ui.select

```lua
require("endpoint").setup({
  picker = "vim_ui_select",
  picker_opts = {
    vim_ui_select = {
      prompt = "Choose endpoint: ",
      kind = "endpoint", -- Useful for dressing.nvim theming
      format_item = function(item)
        return item.display_value
      end
    }
  }
})
```

**Features:**
- Native Neovim interface
- Works without external dependencies
- Integrates with vim.ui.select overrides (like dressing.nvim)
- Lightweight and simple

## UI Customization

### Display Options

```lua
ui = {
  show_icons = true,     -- Show method icons
  show_method = true,    -- Show method text
  
  -- Option 1: Icons only
  show_icons = true,
  show_method = false,
  -- Result: 📥 /api/users
  
  -- Option 2: Method text only
  show_icons = false,
  show_method = true,
  -- Result: GET /api/users
  
  -- Option 3: Both icons and method text
  show_icons = true,
  show_method = true,
  -- Result: 📥 GET /api/users
  
  -- Option 4: Minimal (path only)
  show_icons = false,
  show_method = false,
  -- Result: /api/users
}
```

### Custom Icons and Colors

```lua
ui = {
  method_icons = {
    GET = "🔍",
    POST = "✨",
    PUT = "🔄",
    DELETE = "❌",
    PATCH = "🛠️",
    ROUTE = "🔗", -- React Router
  },
  
  method_colors = {
    GET = "TelescopeResultsNumber",
    POST = "TelescopeResultsConstant",
    PUT = "TelescopeResultsKeyword", 
    DELETE = "TelescopeResultsSpecialChar",
    PATCH = "TelescopeResultsFunction",
    ROUTE = "TelescopeResultsIdentifier",
  },
}
```

## Framework-Specific Configuration

### Rails Configuration

```lua
frameworks = {
  rails = {
    display_format = "smart", -- "action_only", "controller_action", "smart"
    show_action_annotation = true, -- Show [controller#action] annotations
  },
}
```

**Display Format Options:**

- **`"action_only"`**: Show only action name  
  → `GET[#index] /users`

- **`"controller_action"`**: Show controller#action  
  → `GET[users#index] /users`

- **`"smart"`**: Smart formatting  
  → Root routes: `GET[home#index] /`  
  → Regular: `GET[users#index] /users`

**Action Annotation Control:**

- `show_action_annotation = true`: Show annotations (default)  
  → `GET[users#index] /users`

- `show_action_annotation = false`: Hide annotations  
  → `GET /users`

## Complete Configuration Example

```lua
require("endpoint").setup({
  -- Core settings
  cache_mode = "session",
  picker = "telescope",
  
  -- Picker configuration
  picker_opts = {
    telescope = {
      theme = "dropdown",
      previewer = true,
      layout_config = { width = 0.9, height = 0.7 }
    },
  },
  
  -- UI customization
  ui = {
    show_icons = true,
    show_method = true,
    method_icons = {
      GET = "📥", POST = "📤", PUT = "✏️",
      DELETE = "🗑️", PATCH = "🔧", ROUTE = "🔗"
    },
    method_colors = {
      GET = "TelescopeResultsNumber",
      POST = "TelescopeResultsConstant",
      PUT = "TelescopeResultsKeyword",
      DELETE = "TelescopeResultsSpecialChar",
      PATCH = "TelescopeResultsFunction",
      ROUTE = "TelescopeResultsIdentifier",
    },
  },
  
  -- Framework-specific settings
  frameworks = {
    rails = {
      display_format = "smart",
      show_action_annotation = true,
    },
  },
})
```