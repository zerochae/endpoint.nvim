# Framework Development Guide

> **Easy Framework Creation System** 🚀
> Add support for any web framework in just 5 minutes!

## Table of Contents

- [Quick Start](#quick-start)
- [Framework Strategies](#framework-strategies)
- [Creation Methods](#creation-methods)
- [Advanced Usage](#advanced-usage)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

### 🚀 5-Minute Framework Addition

```lua
local factory = require("endpoint.core.framework_factory")

-- Add Laravel support in 5 minutes
local laravel = factory.create_quick_pattern_framework({
  name = "laravel",
  file_extensions = {"*.php"},
  patterns = {
    GET = {"Route::get\\(", "->get\\("},
    POST = {"Route::post\\(", "->post\\("},
    PUT = {"Route::put\\(", "->put\\("},
    DELETE = {"Route::delete\\(", "->delete\\("},
    ALL = {"Route::(get|post|put|delete)\\(", "->(get|post|put|delete)\\("},
  },
  dependencies = {"laravel/framework"},
  files = {"artisan", "composer.json"},
})

-- Register and you're done!
factory.register_framework("laravel", laravel)
```

---

## Framework Strategies

Choose the right strategy for your framework:

### 🎯 Pattern Matching
**Best for:** Annotation/decorator-based frameworks

```lua
-- Examples: Spring Boot, ASP.NET Core, FastAPI
strategy = strategies.STRATEGY_TYPES.PATTERN_MATCHING
```

**Characteristics:**
- ✅ **Fast**: Simple pattern matching
- ✅ **Simple**: Easy to implement
- ✅ **Clear**: Annotations are explicit
- ❌ **Limited**: Can't handle complex routing logic

---

### 🔍 Comprehensive Analysis
**Best for:** Complex routing structures

```lua
-- Examples: Django, Rails
strategy = strategies.STRATEGY_TYPES.COMPREHENSIVE
```

**Characteristics:**
- ✅ **Accurate**: Understands full framework structure
- ✅ **Method-specific**: Points to exact implementation lines
- ✅ **Complex routing**: Handles nested routes, middlewares
- ❌ **Slower**: Initial scan takes longer
- ❌ **Complex**: More implementation work

---

### ⚖️ Hybrid
**Best for:** Frameworks with nested structures

```lua
-- Examples: Ktor, NestJS
strategy = strategies.STRATEGY_TYPES.HYBRID
```

**Characteristics:**
- ✅ **Balanced**: Fast + accurate
- ✅ **Context-aware**: Analyzes surrounding code
- ✅ **Flexible**: Handles various patterns
- ❌ **Moderate complexity**: Middle ground

---

## Creation Methods

### Method 1: Quick Pattern Framework

For simple frameworks with clear patterns:

```lua
local factory = require("endpoint.core.framework_factory")

local framework = factory.create_quick_pattern_framework({
  name = "gin",                           -- Framework name
  file_extensions = {"*.go"},             -- File types to search
  patterns = {                            -- HTTP method patterns
    GET = {"router\\.GET\\(", "\\.GET\\("},
    POST = {"router\\.POST\\(", "\\.POST\\("},
    -- ... more patterns
    ALL = {"router\\.(GET|POST|PUT|DELETE)\\("},
  },
  dependencies = {"github.com/gin-gonic/gin"}, -- Package dependencies
  files = {"go.mod"},                     -- Required files
  exclude_patterns = {"vendor"},          -- Directories to exclude
})

factory.register_framework("gin", framework)
```

### Method 2: Template Generator

For standard structure with customization:

```lua
local templates = require("endpoint.core.framework_templates")
local strategies = require("endpoint.core.strategies")

local config = {
  framework_name = "actix_web",
  language = "rust",
  strategy = strategies.STRATEGY_TYPES.PATTERN_MATCHING,
  file_extensions = {"*.rs"},
  route_patterns = {
    GET = {"web::get\\(\\)", "#\\[get\\("},
    POST = {"web::post\\(\\)", "#\\[post\\("},
    -- ... more patterns
  },
  detection_files = {"Cargo.toml"},
  dependencies = {"actix-web"},
  exclude_dirs = {"target"},
}

-- Generate complete framework file
templates.create_framework_file(config, "./actix_web.lua")
```

### Method 3: Full Custom Implementation

For complex frameworks needing full control:

```lua
local interface = require("endpoint.core.framework_interface")
local strategies = require("endpoint.core.strategies")

-- Define configuration
local config = {
  name = "custom_framework",
  strategy = strategies.STRATEGY_TYPES.COMPREHENSIVE,
  file_extensions = {"*.ext"},
  exclude_patterns = {},
  search_options = {},
}

local detection = {
  files = {"framework.config"},
  dependencies = {"custom-framework"},
  content_patterns = {"framework_pattern"},
  custom_detector = function()
    -- Custom detection logic
    return vim.fn.filereadable("special_file") == 1
  end,
}

-- Custom analyzer for comprehensive strategy
local analyzer = {
  discover_all_endpoints = function()
    -- Implement full endpoint discovery
    return endpoints
  end,

  get_all_endpoints_for_method = function(method)
    -- Filter endpoints by method
    return filtered_endpoints
  end,

  get_discovery_search_cmd = function()
    -- Return search command for discovery
    return "rg pattern"
  end,
}

local framework = interface.create_comprehensive_framework(config, detection, analyzer)
factory.register_framework("custom_framework", framework)
```

---

## Advanced Usage

### Custom Parse Line Logic

Add custom parsing for complex route patterns:

```lua
-- After creating framework, customize parse_line
function framework.parse_line(line, method)
  local file_path, line_number, column, content = line:match("([^:]+):(%d+):(%d+):(.*)")
  if not content then return nil end

  -- Custom parsing logic for your framework
  local http_method, path = extract_custom_pattern(content)
  if http_method and path then
    return {
      method = http_method:upper(),
      endpoint_path = path,
      file_path = file_path,
      line_number = tonumber(line_number),
      column = tonumber(column),
      display_value = http_method:upper() .. " " .. path,
    }
  end

  return nil
end
```

### Runtime Framework Loading

Load frameworks dynamically:

```lua
-- Load user-defined frameworks from config directory
local user_config_path = vim.fn.stdpath("config") .. "/lua/endpoint/frameworks"

if vim.fn.isdirectory(user_config_path) == 1 then
  local user_frameworks = vim.fn.glob(user_config_path .. "/*.lua", false, true)

  for _, file_path in ipairs(user_frameworks) do
    local name = vim.fn.fnamemodify(file_path, ":t:r")
    local success, framework_module = pcall(dofile, file_path)

    if success then
      factory.register_framework(name, framework_module)
    end
  end
end
```

---

## Examples

### Laravel (PHP)

```lua
local laravel_config = {
  framework_name = "laravel",
  language = "php",
  strategy = strategies.STRATEGY_TYPES.PATTERN_MATCHING,
  file_extensions = {"*.php"},
  route_patterns = {
    GET = {"Route::get\\(", "->get\\(", "@Route.*methods.*GET"},
    POST = {"Route::post\\(", "->post\\(", "@Route.*methods.*POST"},
    PUT = {"Route::put\\(", "->put\\(", "@Route.*methods.*PUT"},
    DELETE = {"Route::delete\\(", "->delete\\(", "@Route.*methods.*DELETE"},
    ALL = {
      "Route::(get|post|put|delete|patch)\\(",
      "->(get|post|put|delete|patch)\\(",
      "@Route",
    },
  },
  detection_files = {"artisan", "composer.json"},
  dependencies = {"laravel/framework", "laravel"},
  exclude_dirs = {"vendor", "storage", "bootstrap/cache", "node_modules"},
}
```

### Go Gin

```lua
local gin_config = {
  framework_name = "gin",
  language = "go",
  strategy = strategies.STRATEGY_TYPES.HYBRID,
  file_extensions = {"*.go"},
  route_patterns = {
    GET = {"router\\.GET\\(", "\\.GET\\(", "r\\.GET\\("},
    POST = {"router\\.POST\\(", "\\.POST\\(", "r\\.POST\\("},
    PUT = {"router\\.PUT\\(", "\\.PUT\\(", "r\\.PUT\\("},
    DELETE = {"router\\.DELETE\\(", "\\.DELETE\\(", "r\\.DELETE\\("},
    PATCH = {"router\\.PATCH\\(", "\\.PATCH\\(", "r\\.PATCH\\("},
    ALL = {
      "router\\.(GET|POST|PUT|DELETE|PATCH)\\(",
      "\\.(GET|POST|PUT|DELETE|PATCH)\\(",
      "r\\.(GET|POST|PUT|DELETE|PATCH)\\(",
    },
  },
  detection_files = {"go.mod", "go.sum"},
  dependencies = {"github.com/gin-gonic/gin"},
  exclude_dirs = {"vendor", "bin"},
}
```

### Rust Actix Web

```lua
local actix_config = {
  framework_name = "actix_web",
  language = "rust",
  strategy = strategies.STRATEGY_TYPES.PATTERN_MATCHING,
  file_extensions = {"*.rs"},
  route_patterns = {
    GET = {
      "web::get\\(\\)",
      "#\\[get\\(",
      "\\.route\\(.*web::get\\(\\)",
      "HttpResponse::get",
    },
    POST = {
      "web::post\\(\\)",
      "#\\[post\\(",
      "\\.route\\(.*web::post\\(\\)",
      "HttpResponse::post",
    },
    -- ... more methods
    ALL = {
      "web::(get|post|put|delete|patch)\\(\\)",
      "#\\[(get|post|put|delete|patch)\\(",
      "HttpResponse::(get|post|put|delete|patch)",
    },
  },
  detection_files = {"Cargo.toml"},
  dependencies = {"actix-web", "actix"},
  exclude_dirs = {"target", "deps"},
}
```

---

## Troubleshooting

### Framework Not Detected

1. **Check detection files**: Make sure required files exist
2. **Verify dependencies**: Check package files contain framework dependencies
3. **Test detection logic**: Run detection manually

```lua
local framework = factory.get_framework("your_framework")
print("Detected:", framework and framework.detect())
```

### Routes Not Found

1. **Verify patterns**: Test regex patterns match your route definitions
2. **Check file extensions**: Ensure correct file types are searched
3. **Exclude patterns**: Make sure important files aren't excluded

```lua
-- Test search command
local framework = factory.get_framework("your_framework")
local cmd = framework.get_search_cmd("ALL")
print("Search command:", cmd)
```

### Parse Errors

1. **Debug line parsing**: Check what content is being parsed

```lua
-- Add debug output to parse_line
function framework.parse_line(line, method)
  print("Parsing line:", line)
  print("Content:", content)
  -- ... rest of parsing logic
end
```

2. **Test regex patterns**: Verify patterns match expected content

```lua
local content = "Route::get('/users', 'UserController@index')"
local method, path = content:match("Route::(%w+)\\('([^']+)'")
print("Method:", method, "Path:", path)
```

---

## Contributing

### Adding Built-in Framework Support

1. Create framework file using templates
2. Add comprehensive tests
3. Update documentation
4. Submit PR with examples

### Framework Requirements Checklist

- [ ] **Detection logic** works correctly
- [ ] **Search patterns** cover all route types
- [ ] **Parse logic** extracts method and path accurately
- [ ] **File extensions** include all relevant types
- [ ] **Exclude patterns** avoid irrelevant directories
- [ ] **Test cases** cover common scenarios
- [ ] **Documentation** explains usage and patterns

---

## API Reference

### Core Classes

- `endpoint.core.strategies` - Strategy definitions and framework mapping
- `endpoint.core.framework_interface` - Base interfaces for frameworks
- `endpoint.core.framework_factory` - Framework creation and management
- `endpoint.core.framework_templates` - Template generation utilities

### Key Methods

- `factory.create_quick_pattern_framework(config)` - Quick framework creation
- `factory.register_framework(name, framework)` - Register framework
- `factory.detect_framework()` - Auto-detect framework
- `templates.create_framework_file(config, path)` - Generate framework file

---

*Happy framework hacking! 🚀*