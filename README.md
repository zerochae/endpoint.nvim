# endpoint.nvim

A powerful Neovim plugin for quickly finding and navigating web framework API endpoints with multiple picker interfaces and smart caching.

**Supported Frameworks:**
- 🍃 Spring Boot (Java)
- 🐦 NestJS (TypeScript/JavaScript)
- 🎼 Symfony (PHP)
- ⚡ FastAPI (Python)
- 💎 Rails (Ruby) - ⚠️ Experimental (basic support added but may be incomplete)

## ✨ Features

- 🔍 **Multi-Framework Support**: Automatically detects and supports Spring Boot, NestJS, Symfony, FastAPI, and Rails (experimental)
- 🎯 **Multiple Picker Interfaces**: Choose between Telescope, vim.ui.select, or Snacks.nvim pickers (Snacks picker in development)
- ⚡ **Smart Caching**: Three cache modes - none (real-time), session, and persistent disk storage
- 📍 **Precise Navigation**: Jump directly to the exact line where endpoints are defined
- 🤖 **Auto-Detection**: Automatically detects your project's framework based on project files
- 🎨 **Customizable UI**: Configurable icons, colors, and display options
- 🔧 **Simple Setup**: Just call `require("endpoint").setup()` to get started

## 🚀 Usage

### Primary Commands

```vim
:Endpoint Get      " Find all GET endpoints
:Endpoint Post     " Find all POST endpoints  
:Endpoint Put      " Find all PUT endpoints
:Endpoint Delete   " Find all DELETE endpoints
:Endpoint Patch    " Find all PATCH endpoints
:Endpoint All      " Find all endpoints (default)
```

### Cache Management

```vim
:Endpoint ClearCache   " Clear all cached data
:Endpoint CacheStatus  " Show current cache statistics
```

### Telescope Extension (when using Telescope picker)

```vim
:Telescope endpoint        " All endpoints using Telescope interface
:Telescope endpoint get    " GET endpoints in Telescope
:Telescope endpoint post   " POST endpoints in Telescope
:Telescope endpoint put    " PUT endpoints in Telescope
:Telescope endpoint delete " DELETE endpoints in Telescope
:Telescope endpoint patch  " PATCH endpoints in Telescope
```

## 📦 Installation

> **⚠️ Important**: You must call `require("endpoint").setup()` in a `config` function for the plugin to work properly. The `opts` table alone is not sufficient.

### lazy.nvim

```lua
{
  "zerochae/endpoint.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim", -- Optional: only needed if using telescope picker
  },
  cmd = { "Endpoint" },
  config = function()
    require("endpoint").setup({
      -- Cache configuration
      cache_mode = "none", -- "none" (real-time), "session", "persistent"
      debug = false,
      
      -- Picker configuration
      picker = "telescope", -- "telescope", "vim_ui_select" ("snacks" in development)
      
      -- UI configuration
      ui = {
        show_icons = true,     -- Show method icons
        show_method = true,    -- Show method text (GET, POST, etc.)
        
        -- Method icons
        method_icons = {
          GET    = "📥",
          POST   = "📤", 
          PUT    = "✏️",
          DELETE = "🗑️",
          PATCH  = "🔧",
        },
        
        -- Method colors (highlight groups)
        method_colors = {
          GET    = "TelescopeResultsNumber",
          POST   = "TelescopeResultsConstant",
          PUT    = "TelescopeResultsKeyword",
          DELETE = "TelescopeResultsSpecialChar",
          PATCH  = "TelescopeResultsFunction",
        },
      },
    })
  end,
}
```

## ⚙️ Configuration Options

Configure all settings via setup():

```lua
require("endpoint").setup({
  -- Cache configuration
  cache_mode = "session", -- "none" (real-time), "session", "persistent"
  debug = false,
  
  -- Picker selection
  picker = "telescope", -- "telescope", "vim_ui_select", "snacks"
  picker_opts = {}, -- Additional options passed to picker
  
  -- HTTP methods to search for
  methods = { "GET", "POST", "PUT", "DELETE", "PATCH" },
  
  -- Additional ripgrep arguments
  rg_additional_args = "",
  
  -- UI customization
  ui = {
    show_icons = true,        -- Show method icons
    show_method = true,       -- Show method text (GET, POST, etc.)
    
    -- Method icons
    method_icons = {
      GET = "📥",
      POST = "📤",
      PUT = "✏️",
      DELETE = "🗑️",
      PATCH = "🔧",
    },
    
    -- Method colors (highlight groups)
    method_colors = {
      GET = "TelescopeResultsNumber",
      POST = "TelescopeResultsConstant",
      PUT = "TelescopeResultsKeyword",
      DELETE = "TelescopeResultsSpecialChar",
      PATCH = "TelescopeResultsFunction",
    },
  }
})
```

### Quick Start

```lua
{
  "zerochae/endpoint.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  cmd = { "Endpoint" },
  config = function()
    require("endpoint").setup()
  end,
}
```

### packer.nvim

```lua
use {
  "zerochae/endpoint.nvim",
  requires = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("endpoint").setup()
  end,
}
```

### Default Configuration

```lua
require("endpoint").setup({
  cache_mode = "none",                     -- "none", "session", "persistent"
  debug = false,                            -- Enable debug logging
  picker = "telescope",                     -- "telescope", "vim_ui_select", "snacks"
  picker_opts = {},                         -- Additional picker options
  methods = { "GET", "POST", "PUT", "DELETE", "PATCH" },
  rg_additional_args = "",                  -- Additional ripgrep arguments
  
  ui = {
    show_icons = true,                      -- Show method icons
    show_method = true,                     -- Show method text
    
    method_icons = {
      GET = "📥", POST = "📤", PUT = "✏️", 
      DELETE = "🗑️", PATCH = "🔧",
    },
    
    method_colors = {
      GET = "TelescopeResultsNumber",
      POST = "TelescopeResultsConstant", 
      PUT = "TelescopeResultsKeyword",
      DELETE = "TelescopeResultsSpecialChar",
      PATCH = "TelescopeResultsFunction",
    },
  },
})
```

### Display Options

You can customize how endpoints are displayed:

```lua
-- Option 1: Icons only
ui = {
  show_icons = true,
  show_method = false,
}
-- Result: 📥 /api/users

-- Option 2: Method text only (default)
ui = {
  show_icons = false,
  show_method = true,
}
-- Result: GET /api/users

-- Option 3: Both icons and method text
ui = {
  show_icons = true,
  show_method = true,
}
-- Result: 📥 GET /api/users

-- Option 4: Minimal (path only)
ui = {
  show_icons = false,
  show_method = false,
}
-- Result: /api/users
```

## 🎯 Picker Options

The plugin supports multiple UI interfaces for endpoint selection:

### Telescope Picker (Default)
```lua
require("endpoint").setup({
  picker = "telescope", -- Use Telescope interface (requires telescope.nvim)
})
```
- Rich fuzzy search interface
- Preview window with syntax highlighting
- Full Telescope keybinding support
- Best for power users who use Telescope

### Vim UI Select
```lua
require("endpoint").setup({
  picker = "vim_ui_select", -- Use native vim.ui.select
})
```
- Native Neovim interface
- Works without external dependencies
- Integrates with your vim.ui.select override (like dressing.nvim)
- Lightweight and simple

### Snacks Picker (In Development)
```lua
require("endpoint").setup({
  picker = "snacks", -- Use Snacks.nvim picker (coming soon)
})
```
- Modern picker interface using Snacks.nvim
- Currently in development

## 🔧 Advanced Features

### Caching System

The plugin includes an intelligent caching system with three modes:

```lua
{
  cache_mode = "none", -- Cache mode: "none", "session", or "persistent"
  debug = false,          -- Enable debug logging for troubleshooting
}
```

**Cache Modes:**
- `"none"`: Real-time search with no caching - always returns the most up-to-date results (default)
- `"session"`: Cache remains valid until nvim is closed - good balance of performance and freshness
- `"persistent"`: Cache is saved to disk and persists across nvim sessions - best performance for large projects

**Recommended Usage:**
- **Use `"none"`** (default) if you frequently add/modify endpoints during development
- **Use `"session"`** for moderate-sized projects where you want some performance benefits
- **Use `"persistent"`** for large, stable projects where endpoint changes are infrequent

### Cache Management

Manage your cache with these commands:

```vim
:Endpoint ClearCache   " Clear all cached data
:Endpoint CacheStatus  " Show current cache statistics
```

**Persistent Cache Features:**
- 📁 **Project-specific caching**: Each project gets its own cache directory
- 💾 **Disk storage**: Cache survives nvim restarts and system reboots  
- 🚀 **Instant loading**: No re-scanning on subsequent launches
- 🔄 **Smart invalidation**: Automatically detects when files need re-scanning
- 🗂️ **Cache location**: `~/.local/share/nvim/endpoint.nvim/[project-name]/`

### Cache Status

The `:Endpoint CacheStatus` command shows current cache information including:

- Cache mode (none, session, or persistent)
- Number of cached endpoints by method
- Cache timestamps and statistics

**When to use each cache mode:**
- **None**: ✅ Small projects, ✅ Frequently changing endpoints, ❌ Large projects
- **Session**: ✅ Medium projects, ✅ Balance of performance and freshness, ✅ Most use cases
- **Persistent**: ✅ Large projects, ✅ Stable endpoints, ❌ Frequently changing code



## 🖥️ Demo

### Spring 

![spring](https://github.com/user-attachments/assets/67bf9377-902d-4ec5-9a96-ad9f8da51c48)

### Nest.js

![nest](https://github.com/user-attachments/assets/9dc987d2-e1c1-4bf8-bec4-dc6494fc7b46)


### Cache Status UI

![cache-status](https://github.com/user-attachments/assets/ddd73cbf-9ef9-4cdf-9206-bd44c3700826)

## ⚡️ Requirements

- [Neovim](https://neovim.io/) >= 0.8.0
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional, only needed if using telescope picker)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for fast searching)

## 🔧 Adding New Frameworks

The plugin uses a simple framework-based architecture. Each framework is implemented as a separate Lua module.

### Framework Structure

Frameworks are located in `lua/endpoint/frameworks/` and must implement:

```lua
-- Framework detection
function M.detect()
  -- Return true if framework is detected in current directory
end

-- Generate search command for method
function M.get_search_cmd(method)
  -- Return ripgrep command to find endpoints
end

-- Parse search results
function M.parse_line(line)
  -- Parse ripgrep output line and return endpoint data
end
```

### Example: Adding a New Framework

Create `lua/endpoint/frameworks/myframework.lua`:

```lua
local M = {}

-- Detect framework by checking for specific files
function M.detect()
  return vim.fn.filereadable("myframework.config") == 1
end

-- Generate ripgrep command for finding endpoints
function M.get_search_cmd(method)
  local patterns = {
    GET = { "@get", "@route.*GET" },
    POST = { "@post", "@route.*POST" },
    PUT = { "@put", "@route.*PUT" },
    DELETE = { "@delete", "@route.*DELETE" },
    PATCH = { "@patch", "@route.*PATCH" },
    ALL = { "@get", "@post", "@put", "@delete", "@patch", "@route" },
  }
  
  local method_patterns = patterns[method] or {}
  local pattern_arg = table.concat(method_patterns, "|")
  
  return string.format(
    'rg --type py --line-number --column "%s" .',
    pattern_arg
  )
end

-- Parse ripgrep output into endpoint data
function M.parse_line(line)
  local file, line_num, col, content = line:match("([^:]+):(%d+):(%d+):(.*)")
  if not file then return nil end
  
  -- Extract path from @route("/users") or similar
  local path = content:match('@route%("([^"]*)")') or "/unknown"
  
  -- Extract method from content
  local method = "GET" -- Default
  if content:match("@post") then method = "POST"
  elseif content:match("@put") then method = "PUT"
  elseif content:match("@delete") then method = "DELETE"
  elseif content:match("@patch") then method = "PATCH"
  end
  
  return {
    method = method,
    path = path,
    file = file,
    line = tonumber(line_num),
    col = tonumber(col),
    content = content,
  }
end

return M
```

Then register it in `lua/endpoint/scanner.lua` by adding it to the frameworks table:

```lua
-- In lua/endpoint/scanner.lua
local frameworks = {
  spring = require "endpoint.frameworks.spring",
  fastapi = require "endpoint.frameworks.fastapi",
  nestjs = require "endpoint.frameworks.nestjs",
  symfony = require "endpoint.frameworks.symfony",
  myframework = require "endpoint.frameworks.myframework", -- Add your framework here
}
```

### Contributing Framework Support

We'd love to include your framework! Please submit a PR with:
- Framework implementation file in `lua/endpoint/frameworks/`
- Registration in `lua/endpoint/scanner.lua`
- Basic test cases
- Update to the supported frameworks list in README

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.


### Framework Detection

The plugin uses these files to detect your framework:

- **Spring Boot**: `pom.xml`, `build.gradle`, `build.gradle.kts`, `application.properties`, `application.yml`
- **NestJS**: `package.json` (with @nestjs dependencies), `nest-cli.json`
- **Symfony**: `composer.json` (with symfony framework), `symfony.lock`
- **FastAPI**: `main.py`, `requirements.txt` (with FastAPI)
- **Rails**: `Gemfile` (with Rails gem) - *⚠️ Experimental support*

## 📄 License

This project is licensed under the MIT License.

## ⭐ Star History

If this plugin helps you, please consider giving it a star! ✨
