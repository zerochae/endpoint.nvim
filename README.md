<div align="center">
  <img width="256" height="256" alt="image" src="https://github.com/user-attachments/assets/fdfa853a-9a6f-46f8-9fbb-9b2f55aaf5d2" />
</div>

# endpoint.nvim

A powerful Neovim plugin for quickly finding and navigating web framework API endpoints with multiple picker interfaces and smart caching.

**Supported Frameworks:**
- Spring Boot (Java)
- Java Servlet (Java) 
- NestJS (TypeScript/JavaScript)
- Symfony (PHP)
- FastAPI (Python)
- Rails (Ruby)
- Express (Node.js)
- Ktor (Kotlin)
- .NET Core (C#)
- React Router (Client-side routing)

## 🖥️ Demo

<img width="2294" height="1374" alt="스크린샷 2025-09-06 16 46 59" src="https://github.com/user-attachments/assets/78920f36-7584-457b-9380-147e0e9ba16e" />
<img width="2294" height="1374" alt="스크린샷 2025-09-14 01 08 58" src="https://github.com/user-attachments/assets/bd9ddc7d-8929-4f57-9234-c521d7fb59e8" />
<img width="2294" height="1374" alt="스크린샷 2025-09-13 21 49 37" src="https://github.com/user-attachments/assets/3e73da4d-4400-48fa-8f3d-d6fd2b7daf3c" />
<img width="2294" height="1432" alt="스크린샷 2025-09-13 20 18 11" src="https://github.com/user-attachments/assets/abe4c2f3-872b-4a45-aa09-c4f0857df37c" />


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
:Endpoint Delete   " Find DELETE endpoints
:Endpoint ClearCache   " Clear cached data
:Endpoint CacheStatus  " Show cache statistics
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
    -- vim.ui.select picker works without dependencies
  },
  cmd = { "Endpoint" },
  config = function()
    require("endpoint").setup()
  end,
}
```

## ⚙️ Configuration

```lua
require("endpoint").setup({
  -- New improved config structure (v1.1+)
  cache = {
    mode = "none",        -- "none", "session", "persistent"
  },
  picker = {
    type = "telescope",   -- "telescope", "vim_ui_select", "snacks"
    options = {
      telescope = { theme = "dropdown" },
      snacks = { preview = "file" },
    },
  },
  ui = {
    show_icons = true,
    show_method = true,
    methods = {
      GET = { icon = "📥", color = "TelescopeResultsNumber" },
      POST = { icon = "📤", color = "TelescopeResultsConstant" },
      PUT = { icon = "✏️", color = "TelescopeResultsKeyword" },
      DELETE = { icon = "🗑️", color = "TelescopeResultsSpecialChar" },
      PATCH = { icon = "🔧", color = "TelescopeResultsFunction" },
    },
  },
  frameworks = {
    rails = {
      display_format = "smart",
      show_action_annotation = true,
    },
  },
})
```

**Legacy Configuration (still supported with deprecation warnings):**
```lua
require("endpoint").setup({
  cache_mode = "none",        -- @deprecated: use cache.mode
  picker = "telescope",       -- @deprecated: use picker.type
  picker_opts = {             -- @deprecated: use picker.options
    telescope = { theme = "dropdown" },
  },
  ui = {
    show_icons = true,
    show_method = true,
    method_icons = {          -- @deprecated: use ui.methods
      GET = "📥", POST = "📤", PUT = "✏️", 
      DELETE = "🗑️", PATCH = "🔧"
    },
    method_colors = {         -- @deprecated: use ui.methods
      GET = "TelescopeResultsNumber",
      POST = "TelescopeResultsConstant",
    },
  },
})
```

## 🎯 Picker Options

- **Telescope** (default): Rich fuzzy search with preview
- **vim.ui.select**: Native Neovim interface, works with dressing.nvim
- **Snacks**: Modern picker with file preview and line highlighting

## 🔧 Caching

- **`"none"`** (default): Real-time search, always up-to-date
- **`"session"`**: Cache until nvim closes, good performance balance
- **`"persistent"`**: Disk cache, best for large stable projects

## ⚡️ Requirements

- Neovim >= 0.8.0
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- Optional: telescope.nvim or snacks.nvim for enhanced UI

## 🤝 Contributing

Contributions welcome! To add a new framework:

1. Create `lua/endpoint/frameworks/yourframework.lua`
2. Implement `detect()`, `get_search_cmd()`, and `parse_line()` functions
3. Register in `lua/endpoint/scanner.lua`
4. Add test cases

See existing framework files for examples.

## 📄 License

MIT License
