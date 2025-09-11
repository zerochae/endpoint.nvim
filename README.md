# endpoint.nvim

A powerful Telescope picker for quickly finding and navigating web framework API endpoints with customizable UI and smart caching.

**Supported Frameworks:**
- 🍃 Spring Boot (Java)
- 🐦 NestJS (TypeScript/JavaScript)
- 🎼 Symfony (PHP)
- ⚡ FastAPI (Python)
- 🐍 Django (Python) - Coming soon
- 💎 Rails (Ruby) - Coming soon
- ⚡ Express (Node.js) - Coming soon

## ✨ Features

- 🔍 **Multi-Framework Support**: Automatically detects and supports Spring Boot, NestJS, Symfony, FastAPI, and more
- 🎨 **Customizable UI**: Configurable icons, colors, and display options
- ⚡ **Smart Caching**: Multiple cache modes including real-time search, session, and persistent disk storage
- 🔗 **Path Variable Support**: Handles complex path variables and routing patterns
- 📍 **Precise Navigation**: Jump directly to the exact line with annotation highlighting
- 🌈 **Syntax Highlighting**: Preview window with framework-specific syntax highlighting
- 🤖 **Auto-Detection**: Automatically detects your project's framework
- 🎯 **Flexible UI Options**: Choose between Telescope or native vim.ui.select interface
- 🔧 **Easy Setup**: Just call `require("endpoint").setup()` to get started

## 🚀 Usage

### Simple Commands (Recommended)

```vim
:Endpoint Get      " Find all GET endpoints
:Endpoint Post     " Find all POST endpoints  
:Endpoint Put      " Find all PUT endpoints
:Endpoint Delete   " Find all DELETE endpoints
:Endpoint Patch    " Find all PATCH endpoints
```

### Cache Management Commands

```vim
:Endpoint ClearCache    " Clear all cached data
:Endpoint CacheStatus   " Show current cache status with tree view
```

### Telescope Extension

```vim
:Telescope endpoint        " Default picker
:Telescope endpoint get    " GET endpoints
:Telescope endpoint post   " POST endpoints
:Telescope endpoint put    " PUT endpoints
:Telescope endpoint delete " DELETE endpoints
:Telescope endpoint patch  " PATCH endpoints
```

## 📦 Installation

> **⚠️ Important**: You must call `require("endpoint").setup()` in a `config` function for the plugin to work properly. The `opts` table alone is not sufficient.

### lazy.nvim

```lua
{
  "zerochae/endpoint.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  cmd = {
    "Endpoint",
  },
  config = function()
    require("endpoint").setup({
      -- Framework configuration
      framework = "auto", -- "auto", "spring", "nestjs", "symfony", "fastapi", "django", "rails", "express"
      
      -- Optional: Path-based framework overrides
      framework_paths = {
        ["/path/to/spring/project"] = "spring",
        ["/path/to/nestjs/project"] = "nestjs",
        ["/path/to/symfony/project"] = "symfony",
        ["/path/to/fastapi/project"] = "fastapi",
      },
      
      -- Cache configuration
      cache_mode = "none", -- Cache mode: "none" (real-time), "session", or "persistent"
      debug = false, -- Enable debug logging
      
      -- Picker configuration (optional)
      picker = "auto", -- "auto", "telescope", "vim_ui_select"
      
      ui = {
        show_icons = true,     -- Show method icons
        show_method = true,    -- Show method text (GET, POST, etc.)
        use_nerd_font = false, -- Use nerd font glyphs instead of emojis
        
        -- Customize icons (requires show_icons = true)
        method_icons = {
          emoji = {
            GET    = "📥",
            POST   = "📤", 
            PUT    = "✏️",
            DELETE = "🗑️",
            PATCH  = "🔧",
          },
          nerd_font = {
            GET    = "",  -- download icon
            POST   = "",  -- upload icon  
            PUT    = "",   -- edit icon
            DELETE = "", -- trash icon
            PATCH  = "",  -- wrench icon
          },
        },
        
        -- Customize colors
        method_colors = {
          GET    = "DiagnosticOk",      -- Green
          POST   = "DiagnosticInfo",    -- Blue
          PUT    = "DiagnosticWarn",    -- Yellow
          DELETE = "DiagnosticError",   -- Red
          PATCH  = "DiagnosticHint",    -- Purple
        },
        
        -- Cache status UI customization
        cache_status_icons = {
          emoji = {
            title = "🚀", success = "✅", error = "❌",
            tree = "🌳", directory = "📁", file = "📄"
          },
          nerd_font = {
            title = "", success = "", error = "",
            tree = "", directory = "", file = ""
          },
        },
        
        -- Cache status syntax highlighting
        cache_status_highlight = {
          title = "Special",
          success = "DiagnosticOk", 
          error = "DiagnosticError",
          key = "Keyword",
          tree_method = "Function",
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
  -- Cache mode: "none" (real-time), "session" (temporary), or "persistent" (saved to disk)  
  cache_mode = "none", -- Default: real-time search for most up-to-date results
  
  -- Framework detection: "auto" or specific framework
  framework = "auto", -- "spring", "nestjs", "symfony", "fastapi", "django", "rails", "express"
  
  -- Debug logging
  debug = false,
  
  -- Picker selection
  picker = "auto", -- "auto", "telescope", "vim_ui_select"
  
  -- File patterns and exclusions (overrides framework defaults)
  file_patterns = { "**/*.ts", "**/*.js", "**/*.java" },
  exclude_patterns = { "**/node_modules/**", "**/target/**", "**/dist/**" },
  rg_additional_args = "", -- Additional ripgrep options
  
  -- Complete UI customization
  ui = {
    show_icons = true,        -- Show method icons
    show_method = true,       -- Show method text (GET, POST, etc.)
    use_nerd_font = false,    -- Use nerd font glyphs instead of emojis
    
    -- Method icons
    method_icons = {
      emoji = {
        GET = "📥", POST = "📤", PUT = "✏️", DELETE = "🗑️", PATCH = "🔧"
      },
      nerd_font = {
        GET = "", POST = "", PUT = "", DELETE = "", PATCH = ""
      }
    },
    
    -- Method colors (highlight groups)
    method_colors = {
      GET = "DiagnosticOk",     -- Green
      POST = "DiagnosticInfo",   -- Blue  
      PUT = "DiagnosticWarn",    -- Yellow
      DELETE = "DiagnosticError", -- Red
      PATCH = "DiagnosticHint",   -- Purple
    },
    
    -- Cache status UI icons
    cache_status_icons = {
      emoji = {
        title = "🚀", success = "✅", error = "❌",
        tree = "🌳", directory = "📁", file = "📄"
      },
      nerd_font = {
        title = "", success = "", error = "",
        tree = "", directory = "", file = ""
      }
    },
    
    -- Cache status syntax highlighting
    cache_status_highlight = {
      title = "Special",
      success = "DiagnosticOk",
      error = "DiagnosticError", 
      key = "Keyword",
      tree_method = "Function"
    }
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
    require("endpoint").setup({
      cache_mode = "session", -- Use session cache for better performance
      ui = { use_nerd_font = true } -- Use nerd font icons
    })
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

## ⚙️ Configuration

### Default Configuration

```lua
require("endpoint").setup({
  -- Framework configuration
  framework = "auto",                       -- "auto", "spring", "nestjs", "django", "rails", "express"
  framework_paths = {},                     -- Path-based framework overrides
  
  -- Cache configuration
  cache_mode = "none",                      -- Cache mode: "none" (real-time), "session", or "persistent"
  debug = false,                            -- Enable debug logging
  
  ui = {
    show_icons = false,                     -- Show method icons
    show_method = true,                     -- Show method text
    use_nerd_font = false,                  -- Use nerd font glyphs instead of emojis
    
    method_colors = {
      GET = "TelescopeResultsNumber",
      POST = "TelescopeResultsConstant", 
      PUT = "TelescopeResultsKeyword",
      DELETE = "TelescopeResultsSpecialChar",
      PATCH = "TelescopeResultsFunction",
    },
    
    method_icons = {
      emoji = {
        GET = "📥", POST = "📤", PUT = "✏️", 
        DELETE = "🗑️", PATCH = "🔧",
      },
      nerd_font = {
        GET = "", POST = "", PUT = "",
        DELETE = "", PATCH = "",
      },
    },
    
    -- Cache status UI customization
    cache_status_icons = {
      emoji = {
        title = "🚀", success = "✅", error = "❌",
        tree = "🌳", directory = "📁", file = "📄"
      },
      nerd_font = {
        title = "", success = "", error = "",
        tree = "", directory = "", file = ""
      },
    },
    
    cache_status_highlight = {
      title = "Special", success = "String", error = "ErrorMsg",
      key = "Keyword", tree_method = "Function",
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

The plugin supports two different UI interfaces for endpoint selection:

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

### Auto Detection
```lua
require("endpoint").setup({
  picker = "auto", -- Automatically choose best available option (default)
})
```
- Uses Telescope if available, falls back to vim.ui.select
- Recommended for most users

## 🔧 Advanced Features

### Caching System

The plugin includes an intelligent caching system with three modes:

```lua
{
  cache_mode = "none", -- Cache mode: "none", "session", or "persistent"
  debug = false,       -- Enable debug logging for troubleshooting
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

### Persistent Cache Mode

The persistent cache mode offers the best performance for large projects:

```lua
require("endpoint").setup({
  cache_mode = "persistent",
  -- debug = true, -- Set to true for troubleshooting
})
```

**Features:**
- 📁 **Project-specific caching**: Each project gets its own cache directory
- 💾 **Disk storage**: Cache survives nvim restarts and system reboots  
- 🚀 **Instant loading**: No re-scanning on subsequent launches
- 🔄 **Smart invalidation**: Automatically detects when annotations need re-scanning
- 🗂️ **Cache location**: `~/.local/share/nvim/endpoint.nvim/[project-name]/`

**Cache Management:**
```vim
:Endpoint ClearCache    " Clear all cache files for current project
:Endpoint CacheStatus   " Show detailed cache information with beautiful tree view
```

### Cache Status UI

The `:Endpoint CacheStatus` command opens a beautiful, interactive cache status UI featuring:

- 🎨 **ASCII Art Headers**: Clean, professional interface
- 🌳 **Tree Structure**: Hierarchical view of cached files and endpoints
- 📊 **Detailed Statistics**: File counts, endpoint counts, framework detection
- 🎯 **Project Information**: Current cache mode, project config status
- ⚡ **Keyboard Navigation**: Press `q` to close

**Features:**
- Project-specific configuration detection
- Framework-specific endpoint grouping  
- File size information for persistent cache
- Visual indicators for success/error states
- Nerd font support with `use_nerd_font = true`

**Cache Files Structure:**
```text
~/.local/share/nvim/endpoint.nvim/[my-project]/
├── find_cache.lua    " Endpoint data (paths, methods, locations)
└── metadata.lua      " Scan history and project metadata
```

**When to use persistent mode:**
- ✅ Large projects with many API endpoints
- ✅ Frequent nvim restarts during development
- ✅ Want maximum performance after initial scan
- ❌ Small projects (overhead not worth it)
- ❌ API endpoints change very frequently

### Custom File Patterns

Customize which files to search:

```lua
{
  file_patterns = { "**/*.java", "**/*.kt" },  -- Java and Kotlin
  exclude_patterns = { 
    "**/target/**", 
    "**/build/**", 
    "**/node_modules/**" 
  },
}
```

### Project-Specific Configuration

Configure different settings for different projects:

```lua
require("endpoint").setup({
  framework = "auto",    -- Default framework detection
  cache_mode = "none",   -- Default: real-time search for all projects
  
  -- Project-specific framework overrides
  framework_paths = {
    ["/path/to/spring/project"] = "spring",
    ["/path/to/nestjs/project"] = "nestjs",
    ["/path/to/symfony/project"] = "symfony",
    ["/path/to/express/project"] = "express",
  },
  
  -- Project-specific cache mode overrides
  cache_mode_paths = {
    ["/path/to/large-stable-project"] = "persistent",  -- Use persistent cache for large, stable projects
    ["/path/to/medium-project"] = "session",           -- Use session cache for moderate projects
    ["/path/to/dev-project"] = "none",                 -- Use real-time for actively developed projects (default)
  },
})
```

**Benefits:**
- 🎯 **Per-project optimization**: Different frameworks and cache strategies per project
- 🔄 **Development flexibility**: Use `"none"` for active development, `"session"` for moderate projects, `"persistent"` for stable projects
- 📁 **Path matching**: Supports both exact paths and parent directory matching
- ⚙️ **Easy management**: Configure once, works across all your projects

**Path Matching Examples:**
```lua
cache_mode_paths = {
  ["/Users/me/work"] = "session",           -- All work projects use session cache
  ["/Users/me/work/large-api"] = "persistent", -- Large project uses persistent cache
  [vim.fn.expand("~/personal")] = "none",   -- Personal projects use real-time search
}
```

## 🖥️ Demo

### Spring 

![spring](https://github.com/user-attachments/assets/67bf9377-902d-4ec5-9a96-ad9f8da51c48)

### Nest.js

![nest](https://github.com/user-attachments/assets/9dc987d2-e1c1-4bf8-bec4-dc6494fc7b46)


### Cache Status UI

![cache-status](https://github.com/user-attachments/assets/ddd73cbf-9ef9-4cdf-9206-bd44c3700826)

## ⚡️ Requirements

- [Neovim](https://neovim.io/) >= 0.8.0
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for fast searching)


## 🔧 Adding New Frameworks

The new modular architecture makes it extremely easy to add support for new web frameworks! Here's how:

### Step 1: Create Framework Configuration

Create a configuration file at `lua/endpoint/framework/config/yourframework.lua`:

```lua
return {
  -- File patterns to search
  file_patterns = { "**/*.py" }, -- or whatever your framework uses
  
  -- Directories to exclude from search  
  exclude_patterns = { "**/venv/**", "**/__pycache__/**" },
  
  -- Files used to detect this framework in a project
  detection_files = { "manage.py", "requirements.txt" },
  
  -- Search patterns for each HTTP method
  patterns = {
    get = { "def.*get.*\\(", "@app\\.get" },
    post = { "def.*post.*\\(", "@app\\.post" },
    put = { "def.*put.*\\(", "@app\\.put" },  
    delete = { "def.*delete.*\\(", "@app\\.delete" },
    patch = { "def.*patch.*\\(", "@app\\.patch" },
  },
}
```

### Step 2: Create Framework Implementation

Create an implementation file at `lua/endpoint/framework/registry/yourframework.lua`:

```lua
-- Your Framework implementation
local base = require("endpoint.framework.base")
local yourframework_config = require("endpoint.framework.config.yourframework")

-- Create framework object inheriting from base
local M = base.new({})

function M:get_patterns(method)
  return yourframework_config.patterns[method:lower()] or {}
end

function M:get_file_types()
  -- Extract file extensions from config
  local file_extensions = {}
  for _, pattern in ipairs(yourframework_config.file_patterns) do
    local ext = pattern:match("%.(%w+)$")
    if ext then
      table.insert(file_extensions, ext)
    end
  end
  return file_extensions
end

function M:get_exclude_patterns()
  return yourframework_config.exclude_patterns
end

-- Extract endpoint path from matched content
function M:extract_endpoint_path(content)
  -- Implement your framework-specific path extraction logic
  local path = content:match('@app%.%w+%("([^"]*)"')  -- Example pattern
  return path or ""
end

-- Extract base path from controller/class annotations
function M:get_base_path(file_path, line_number)
  -- Implement your framework-specific base path logic
  -- This is often empty for many frameworks
  return ""
end

return M
```

### Step 3: That's it! 🎉

Your framework is now automatically:
- ✅ **Detected** when you open projects with the detection files
- ✅ **Available** in the framework dropdown
- ✅ **Loaded** dynamically when needed  
- ✅ **Cached** for performance
- ✅ **Validated** for proper implementation

### Example: Adding FastAPI Support

**1. Config** (`lua/endpoint/framework/config/fastapi.lua`):
```lua
return {
  file_patterns = { "**/*.py" },
  exclude_patterns = { "**/venv/**", "**/__pycache__/**" },
  detection_files = { "main.py", "requirements.txt" },
  patterns = {
    get = { "@app\\.get", "@router\\.get" },
    post = { "@app\\.post", "@router\\.post" },
    put = { "@app\\.put", "@router\\.put" },
    delete = { "@app\\.delete", "@router\\.delete" },
    patch = { "@app\\.patch", "@router\\.patch" },
  },
}
```

**2. Implementation** (`lua/endpoint/framework/registry/fastapi.lua`):
```lua
local base = require("endpoint.framework.base")
local fastapi_config = require("endpoint.framework.config.fastapi")

local M = base.new({})

function M:extract_endpoint_path(content)
  -- Extract path from @app.get("/users") or @app.get("/users/{id}")
  local path = content:match('@%w+%.%w+%("([^"]*)"')
  return path or ""
end

function M:get_base_path(file_path, line_number)
  -- FastAPI usually doesn't have base paths at class level
  return ""
end

-- Standard methods using config
function M:get_patterns(method)
  return fastapi_config.patterns[method:lower()] or {}
end

function M:get_file_types()
  local extensions = {}
  for _, pattern in ipairs(fastapi_config.file_patterns) do
    local ext = pattern:match("%.(%w+)$")
    if ext then table.insert(extensions, ext) end
  end
  return extensions
end

function M:get_exclude_patterns()
  return fastapi_config.exclude_patterns
end

return M
```

The plugin will automatically discover and load your new framework! 

### Testing Your Framework

1. Open a project with your framework
2. Enable debug mode: `require("endpoint").setup({ debug = true })`
3. Check the logs to see if your framework is detected
4. Run `:Telescope endpoint get` to test endpoint discovery

### Contributing Framework Support

We'd love to include your framework in the main repository! Please submit a PR with:
- Framework config file
- Framework implementation  
- Basic test cases
- Update to the supported frameworks list

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🔄 Migration from telescope-spring.nvim

If you're upgrading from the Spring-only version:

1. **Update your setup call**:
   ```lua
   -- Old
   require("spring").setup()
   
   -- New
   require("endpoint").setup()
   ```

2. **Update commands** (optional - old commands still work):
   ```vim
   " Old
   :Spring Get
   
   " New (recommended)
   :Endpoint Get
   ```

3. **Update Telescope extension**:
   ```vim
   " Old
   :Telescope spring get
   
   " New
   :Telescope endpoint get
   ```

All your existing configuration and cache will continue to work!

### Framework-Specific Configuration

The plugin automatically detects your framework, but you can override detection:

```lua
require("endpoint").setup({
  -- Explicit framework selection
  framework = "spring", -- or "nestjs", "symfony", "fastapi", "django", "rails", "express"
  
  -- Path-based framework overrides (useful for monorepos)
  framework_paths = {
    ["/home/user/spring-project"] = "spring",
    ["/home/user/nestjs-api"] = "nestjs",
    ["/home/user/symfony-api"] = "symfony",
    ["/home/user/fastapi-api"] = "fastapi",
    ["/home/user/django-app"] = "django",
  },
  
  debug = true, -- Enable to see framework detection logs
})
```

### Framework Detection

The plugin uses these files to detect your framework:

- **Spring Boot**: `pom.xml`, `build.gradle`, `build.gradle.kts`
- **NestJS**: `package.json` (with @nestjs dependencies)
- **Symfony**: `composer.json`, `symfony.lock`, `config/services.yaml`
- **FastAPI**: `main.py`, `requirements.txt` (with FastAPI)
- **Django**: `manage.py`, `requirements.txt` (with Django)
- **Rails**: `Gemfile` (with Rails gem)
- **Express**: `package.json` (with Express dependencies)

## 📄 License

This project is licensed under the MIT License.

## ⭐ Star History

If this plugin helps you, please consider giving it a star! ✨
