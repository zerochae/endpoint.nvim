<div align="center">
  <img width="256" height="256" alt="image" src="https://github.com/user-attachments/assets/fdfa853a-9a6f-46f8-9fbb-9b2f55aaf5d2" />
</div>

# endpoint.nvim

A powerful Neovim plugin for quickly finding and navigating web framework API endpoints with multiple picker interfaces and smart caching.

**Supported Frameworks:**
- Spring Boot (Java)
- Rails (Ruby)
- Symfony (PHP)
- Express (Node.js)
- NestJS (TypeScript/JavaScript)
- FastAPI (Python)
- .NET Core (C#)
- Ktor (Kotlin)
- Java Servlet (Java)
- React Router (Client-side routing)

## 🖥️ Demo

<img width="2294" height="1374" alt="스크린샷 2025-09-06 16 46 59" src="https://github.com/user-attachments/assets/78920f36-7584-457b-9380-147e0e9ba16e" />
<img width="2294" height="1374" alt="스크린샷 2025-09-14 01 08 58" src="https://github.com/user-attachments/assets/bd9ddc7d-8929-4f57-9234-c521d7fb59e8" />
<img width="2294" height="1374" alt="스크린샷 2025-09-13 21 49 37" src="https://github.com/user-attachments/assets/3e73da4d-4400-48fa-8f3d-d6fd2b7daf3c" />
<img width="2294" height="1432" alt="스크린샷 2025-09-13 20 18 11" src="https://github.com/user-attachments/assets/abe4c2f3-872b-4a45-aa09-c4f0857df37c" />


## ✨ Features

- 🔍 **Multi-Framework Support**: Automatically detects and supports 10 web frameworks
- 🎯 **Multiple Picker Interfaces**: Telescope, vim.ui.select, or Snacks.nvim
- ⚡ **Smart Caching**: Real-time, session, or persistent modes
- 📍 **Precise Navigation**: Jump directly to endpoint definitions
- 🤖 **Auto-Detection**: Automatically detects your project's framework
- 🔧 **Simple Setup**: Just call `require("endpoint").setup()`

## 🚀 Usage

```vim
:Endpoint          " Find all endpoints
:Endpoint Get      " Find GET endpoints
:Endpoint Post     " Find POST endpoints
:Endpoint Put      " Find PUT endpoints
:Endpoint Delete   " Find DELETE endpoints
:Endpoint Patch    " Find PATCH endpoints
:EndpointRefresh   " Force refresh (bypass cache)
```

## 📦 Installation

### lazy.nvim

```lua
{
  "zerochae/endpoint.nvim",
  dependencies = {
    -- Choose one or more pickers (all optional):
    "nvim-telescope/telescope.nvim", -- For telescope picker
    "folke/snacks.nvim",            -- For snacks picker
    "stevearc/dressing.nvim",       -- Enhances vim.ui.select with telescope backend
    -- vim.ui.select picker works without dependencies
  },
  cmd = { "Endpoint", "EndpointRefresh" },
  config = function()
    require("endpoint").setup()
  end,
}
```

## ⚙️ Configuration

```lua
require("endpoint").setup({
  -- Picker configuration
  picker = {
    type = "vim_ui_select", -- "telescope", "vim_ui_select", "snacks"
    options = {
      telescope = {},     -- Telescope-specific options
      snacks = {},        -- Snacks-specific options
      vim_ui_select = {   -- vim.ui.select-specific options
        enable_filter = false,        -- Enable filtering for large lists
        filter_threshold = 20,        -- Show filter prompt when endpoints > threshold
        filter_prompt = "Filter: ",   -- Custom filter prompt
        show_filter_examples = true,  -- Show filter examples in prompt
      },
    },
    -- Previewer configuration
    previewer = {
      enable_highlighting = true, -- Enable syntax highlighting in previewer (default: true)
    },
  },

  -- Cache configuration
  cache = {
    mode = "session",   -- "none", "session", "persistent"
  },

  -- Progress notification configuration
  progress = {
    enabled = true,     -- Enable progress notifications during scan
    provider = "auto",  -- "auto", "fidget", "notify"
    -- auto: Use fidget.nvim if available, fallback to vim.notify
  },

  -- UI configuration
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
})
```

**Legacy Configuration (still supported with deprecation warnings):**
```lua
require("endpoint").setup({
  picker = "telescope",       -- @deprecated: use picker.type
  picker_opts = {             -- @deprecated: use picker.options
    telescope = { theme = "dropdown" },
  },
})
```

## 🎯 Picker Options

⚠️ **Important**: You must set `picker.type` to match your installed picker!

- **Telescope**: `picker.type = "telescope"` - Rich fuzzy search with preview
- **vim.ui.select**: `picker.type = "vim_ui_select"` - Native Neovim interface with smart filtering, enhanced by dressing.nvim
- **Snacks**: `picker.type = "snacks"` - Modern picker with file preview and line highlighting

```lua
-- If you use snacks.nvim
{
  "zerochae/endpoint.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = function()
    require("endpoint").setup({
      picker = { type = "snacks" }
    })
  end,
}

-- If you use telescope.nvim
{
  "zerochae/endpoint.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("endpoint").setup({
      picker = { type = "telescope" }
    })
  end,
}

-- If you use vim.ui.select with dressing.nvim
{
  "zerochae/endpoint.nvim",
  dependencies = { "stevearc/dressing.nvim" },
  config = function()
    require("endpoint").setup({
      picker = {
        type = "vim_ui_select",
        options = {
          vim_ui_select = {
            enable_filter = true,
            filter_threshold = 20,
            filter_prompt = "Filter endpoints: ",
          }
        }
      }
    })
  end,
}
```

## 🔧 Caching

Configure caching behavior for optimal performance:

- **`"none"`**: Real-time search, always up-to-date (no caching)
- **`"session"`** (default): Cache until nvim closes, good performance balance
- **`"persistent"`**: Disk cache, survives nvim restarts until manual refresh

### Cache Storage

Persistent cache files are stored in:
- **Location**: `~/.cache/nvim/endpoint.nvim/`
- **Format**: Lua files for optimal performance
- **Naming**:
  - `{project}.lua` (all endpoints)
  - `{project}_GET.lua` (GET endpoints only)
  - `{project}_POST.lua` (POST endpoints only)

**Example cache files:**
```
~/.cache/nvim/endpoint.nvim/
├── myproject.lua              # All endpoints
├── myproject_GET.lua          # GET endpoints
└── myproject_POST.lua         # POST endpoints
```

Use `:EndpointRefresh` to force refresh (bypass cache).

## ⚡️ Requirements

- Neovim >= 0.8.0
- [ripgrep](https://github.com/BurntSushi/ripgrep)

### Optional Dependencies

| Plugin | Purpose |
|--------|---------|
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Enhanced fuzzy finder UI |
| [snacks.nvim](https://github.com/folke/snacks.nvim) | Modern picker with preview |
| [fidget.nvim](https://github.com/j-hui/fidget.nvim) | Progress notifications during scanning |


## 📄 License

MIT License