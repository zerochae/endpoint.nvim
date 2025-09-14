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
  cache_mode = "none",        -- "none", "session", "persistent"
  picker = "telescope",       -- "telescope", "vim_ui_select", "snacks"
  
  ui = {
    show_icons = true,
    show_method = true,
    method_icons = {
      GET = "📥", POST = "📤", PUT = "✏️", 
      DELETE = "🗑️", PATCH = "🔧"
    },
  },
  
  -- Rails-specific options
  frameworks = {
    rails = {
      display_format = "smart",
      show_action_annotation = true,
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

## 🖥️ Demo

### Spring Boot
![spring](https://github.com/user-attachments/assets/67bf9377-902d-4ec5-9a96-ad9f8da51c48)

### NestJS
![nest](https://github.com/user-attachments/assets/9dc987d2-e1c1-4bf8-bec4-dc6494fc7b46)

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