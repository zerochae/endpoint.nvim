# endpoint.nvim

A powerful Neovim plugin for quickly finding and navigating web framework API endpoints with multiple picker interfaces and smart caching.

**Supported Frameworks:**
- 🍃 Spring Boot (Java)
- 🐦 NestJS (TypeScript/JavaScript)
- 🎼 Symfony (PHP)
- ⚡ FastAPI (Python)
- 💎 Rails (Ruby)

## ✨ Features

- 🔍 **Multi-Framework Support**: Automatically detects and supports Spring Boot, NestJS, Symfony, FastAPI, and Rails
- 🎯 **Multiple Picker Interfaces**: Choose between Telescope, vim.ui.select, or Snacks.nvim pickers (Snacks picker in development)
- ⚡ **Smart Caching**: Three cache modes - none (real-time), session, and persistent disk storage
- 📍 **Precise Navigation**: Jump directly to the exact line where endpoints are defined
- 🤖 **Auto-Detection**: Automatically detects your project's framework based on project files
- 🎨 **Customizable UI**: Configurable icons, colors, and display options
- 💎 **Rails Support**: Full controller actions and routes.rb parsing with customizable display formats
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
      
      -- Picker configuration
      picker = "telescope", -- "telescope", "vim_ui_select", "snacks"
      picker_opts = {}, -- Additional options passed to picker (Telescope only)
      
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
  
  -- Picker selection
  picker = "telescope", -- "telescope", "vim_ui_select", "snacks"
  picker_opts = {}, -- Additional options passed to picker (Telescope only)
  
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
  picker = "telescope",                     -- "telescope", "vim_ui_select", "snacks"
  picker_opts = {},                         -- Additional picker options (Telescope only)
  
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
  
  -- Framework-specific configuration
  frameworks = {
    rails = {
      display_format = "smart", -- "action_only", "controller_action", "smart"
      show_action_annotation = true, -- Show [controller#action] annotations
    },
  },
})
```

### Rails Display Format

Configure how Rails routes are displayed:

```lua
frameworks = {
  rails = {
    display_format = "smart", -- "action_only", "controller_action", "smart"
    show_action_annotation = true, -- Show [controller#action] annotations
  },
}
```

**Display Format Options:**
- `"action_only"`: Show only action name → `GET[#index] /users`
- `"controller_action"`: Show controller#action → `GET[users#index] /users`  
- `"smart"`: Smart formatting → Root routes: `GET[home#index] /`, Regular: `GET[users#index] /users`

**Action Annotation Control:**
- `show_action_annotation = true`: Show action annotations (default)
- `show_action_annotation = false`: Hide annotations → `GET /users` (clean format)

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

## 🧪 Development & Testing

### Running Tests

The plugin includes comprehensive test suites for all supported frameworks. Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) and can be run using the provided Makefile.

#### Prerequisites
```bash
# Install test dependencies (done automatically by tests/minit.lua)
# plenary.nvim and telescope.nvim are fetched automatically
```

#### Test Commands

```bash
# Run all tests
make test

# Test specific frameworks
make test-spring      # Spring Boot framework tests
make test-nestjs      # NestJS framework tests  
make test-symfony     # Symfony framework tests
make test-fastapi     # FastAPI framework tests
make test-rails       # Rails framework tests
make test-oas-rails   # Rails with OAS annotations tests

# Run all framework tests together
make test-frameworks

# Test specific components
make test-cache       # Cache functionality tests
make test-pickers     # Picker interface tests
```

#### Test Structure

```text
tests/
├── fixtures/          # Test fixture projects for each framework
│   ├── spring/        # Sample Spring Boot project
│   ├── nestjs/        # Sample NestJS project  
│   ├── symfony/       # Sample Symfony project
│   ├── fastapi/       # Sample FastAPI project
│   └── rails/         # Sample Rails project
├── spec/              # Test specifications
│   ├── spring_spec.lua
│   ├── nestjs_spec.lua
│   ├── symfony_spec.lua
│   ├── fastapi_spec.lua
│   ├── rails_spec.lua
│   └── oas_rails_spec.lua
└── minit.lua          # Test initialization
```

#### Adding Tests

When contributing new features or framework support:

1. **Framework Tests**: Add test cases to existing `*_spec.lua` files
2. **New Framework**: Create new spec file following existing patterns
3. **Test Fixtures**: Add sample project files to `tests/fixtures/your_framework/`
4. **Makefile**: Add new test targets if needed

#### Debugging Tests

```bash
# Run single test with debug output  
nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedFile tests/spec/spring_spec.lua"

# Check test fixtures
ls tests/fixtures/spring/src/main/java/com/example/

# Validate framework detection in fixture directory
cd tests/fixtures/spring && nvim -c "lua print(require('endpoint.frameworks.spring').detect())"
```

### 🐛 Reporting Issues

#### If Your Endpoints Are Not Being Detected

If the plugin is not finding your endpoints, please help us fix it by providing a reproducible example:

1. **Create a minimal reproduction case** in the appropriate `tests/fixtures/your-framework/` directory
2. **Include the specific code** that is not being detected
3. **Submit a PR** with your test case and a description of the expected behavior

**Example for Spring Boot:**
```bash
# Add your problematic controller to:
tests/fixtures/spring/src/main/java/com/example/ProblematicController.java

# Include methods like:
@RestController
@RequestMapping("/api/v1")
public class ProblematicController {
    @GetMapping("/missing-endpoint")  // This endpoint is not detected
    public ResponseEntity<?> missingEndpoint() { ... }
}
```

**Example for Rails:**  
```bash
# Add your problematic controller/routes to:
tests/fixtures/rails/app/controllers/problematic_controller.rb
tests/fixtures/rails/config/routes.rb

# Include actions like:
class ProblematicController < ApplicationController
  def missing_action  # This action is not detected
    # ...
  end
end
```

This helps us:
- ✅ **Reproduce the issue** consistently
- ✅ **Write proper tests** for the fix  
- ✅ **Prevent regressions** in the future
- ✅ **Improve framework support** for everyone

**Please include:**
- Framework version (e.g., Spring Boot 3.1, Rails 7.0)
- The exact code pattern that's not working
- Expected vs actual behavior


### Framework Detection

The plugin uses these files to detect your framework:

- **Spring Boot**: `pom.xml`, `build.gradle`, `build.gradle.kts`, `application.properties`, `application.yml`
- **NestJS**: `package.json` (with @nestjs dependencies), `nest-cli.json`
- **Symfony**: `composer.json` (with symfony framework), `symfony.lock`
- **FastAPI**: `main.py`, `requirements.txt` (with FastAPI)
- **Rails**: `Gemfile`, `config/routes.rb`, `config/application.rb`, `app/controllers`

## 📄 License

This project is licensed under the MIT License.

## ⭐ Star History

If this plugin helps you, please consider giving it a star! ✨
