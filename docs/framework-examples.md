# Framework Examples

> **Real-world examples** of adding popular frameworks to endpoint.nvim

## Complete Framework Implementations

### 🐘 PHP Laravel

```lua
-- file: ~/.config/nvim/lua/endpoint/frameworks/laravel.lua
local factory = require("endpoint.core.framework_factory")
local strategies = require("endpoint.core.strategies")

-- Laravel framework implementation
local laravel = factory.create_quick_pattern_framework({
  name = "laravel",
  file_extensions = {"*.php"},
  patterns = {
    GET = {
      "Route::get\\(",
      "->get\\(",
      "#\\[Route.*methods.*GET\\]",
      "@Route\\(.*methods.*GET",
    },
    POST = {
      "Route::post\\(",
      "->post\\(",
      "#\\[Route.*methods.*POST\\]",
      "@Route\\(.*methods.*POST",
    },
    PUT = {
      "Route::put\\(",
      "->put\\(",
      "#\\[Route.*methods.*PUT\\]",
      "@Route\\(.*methods.*PUT",
    },
    DELETE = {
      "Route::delete\\(",
      "->delete\\(",
      "#\\[Route.*methods.*DELETE\\]",
      "@Route\\(.*methods.*DELETE",
    },
    PATCH = {
      "Route::patch\\(",
      "->patch\\(",
      "#\\[Route.*methods.*PATCH\\]",
      "@Route\\(.*methods.*PATCH",
    },
    ALL = {
      "Route::(get|post|put|delete|patch)\\(",
      "->(get|post|put|delete|patch)\\(",
      "#\\[Route",
      "@Route",
    },
  },
  dependencies = {"laravel/framework", "laravel"},
  files = {"artisan", "composer.json"},
  exclude_patterns = {"vendor", "storage", "bootstrap/cache", "node_modules"},
})

-- Custom route extraction for Laravel
function laravel.extract_route_info(content, search_method)
  -- Pattern 1: Route::get('/path', 'Controller@method')
  local method, path = content:match("Route::(%w+)%(['\"]([^'\"]+)['\"]")
  if method and path then
    return method:upper(), path
  end

  -- Pattern 2: ->get('/path', function...)
  method, path = content:match("->(%w+)%(['\"]([^'\"]+)['\"]")
  if method and path then
    return method:upper(), path
  end

  -- Pattern 3: Route attributes #[Route('/path', methods: ['GET'])]
  path = content:match("#%[Route%(['\"]([^'\"]+)['\"]")
  if path then
    local methods_str = content:match("methods:%s*%[([^%]]+)%]")
    if methods_str then
      local route_method = methods_str:match("['\"]([^'\"]+)['\"]")
      if route_method then
        return route_method:upper(), path
      end
    end
    return "GET", path -- Default to GET if no method specified
  end

  return nil, nil
end

-- Register Laravel framework
factory.register_framework("laravel", laravel)
return laravel
```

### 🦀 Rust Actix Web

```lua
-- file: ~/.config/nvim/lua/endpoint/frameworks/actix_web.lua
local factory = require("endpoint.core.framework_factory")
local strategies = require("endpoint.core.strategies")

local actix_web = factory.create_quick_pattern_framework({
  name = "actix_web",
  file_extensions = {"*.rs"},
  patterns = {
    GET = {
      "web::get\\(\\)",
      "#\\[get\\(",
      "\\.route\\(.*web::get\\(\\)",
      "HttpRequest::get",
      "web::resource\\(.*\\.get\\(",
    },
    POST = {
      "web::post\\(\\)",
      "#\\[post\\(",
      "\\.route\\(.*web::post\\(\\)",
      "HttpRequest::post",
      "web::resource\\(.*\\.post\\(",
    },
    PUT = {
      "web::put\\(\\)",
      "#\\[put\\(",
      "\\.route\\(.*web::put\\(\\)",
      "web::resource\\(.*\\.put\\(",
    },
    DELETE = {
      "web::delete\\(\\)",
      "#\\[delete\\(",
      "\\.route\\(.*web::delete\\(\\)",
      "web::resource\\(.*\\.delete\\(",
    },
    PATCH = {
      "web::patch\\(\\)",
      "#\\[patch\\(",
      "\\.route\\(.*web::patch\\(\\)",
      "web::resource\\(.*\\.patch\\(",
    },
    ALL = {
      "web::(get|post|put|delete|patch)\\(\\)",
      "#\\[(get|post|put|delete|patch)\\(",
      "web::resource\\(",
    },
  },
  dependencies = {"actix-web", "actix"},
  files = {"Cargo.toml"},
  exclude_patterns = {"target", "deps"},
})

function actix_web.extract_route_info(content, search_method)
  -- Pattern 1: #[get("/path")]
  local path = content:match("#%[get%(\"([^\"]+)\"%)")
  if path then
    return "GET", path
  end

  -- Similar for other methods
  path = content:match("#%[post%(\"([^\"]+)\"%)")
  if path then
    return "POST", path
  end

  -- Pattern 2: web::get().to(handler)
  path = content:match("web::get%(%)%.to%([^)]+%)")
  if path then
    -- Extract path from surrounding context
    return "GET", extract_path_from_context(content)
  end

  -- Pattern 3: .route("/path", web::get().to(handler))
  local route_path, method = content:match("%.route%(\"([^\"]+)\".*web::(%w+)%(")
  if route_path and method then
    return method:upper(), route_path
  end

  return nil, nil
end

factory.register_framework("actix_web", actix_web)
return actix_web
```

### 🐹 Go Gin (Hybrid Strategy)

```lua
-- file: ~/.config/nvim/lua/endpoint/frameworks/gin.lua
local interface = require("endpoint.core.framework_interface")
local strategies = require("endpoint.core.strategies")

-- Gin uses hybrid strategy for better context analysis
local config = {
  name = "gin",
  strategy = strategies.STRATEGY_TYPES.HYBRID,
  file_extensions = {"*.go"},
  exclude_patterns = {"vendor", "bin"},
  search_options = {"--case-sensitive"},
}

local detection = {
  files = {"go.mod", "go.sum"},
  dependencies = {"github.com/gin-gonic/gin"},
  content_patterns = {"gin\\.New", "gin\\.Default"},
}

local patterns = {
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
}

local context_analyzer = {
  analyze_context = function(file_path, line_number)
    -- Analyze Go code for route groups
    local base_paths = {}
    local file = io.open(file_path, "r")
    if not file then return base_paths end

    local lines = {}
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()

    -- Look for route groups: v1 := router.Group("/api/v1")
    local group_stack = {}
    for i = 1, line_number - 1 do
      local line = lines[i]
      if line then
        local group_var, path = line:match("(%w+)%s*:=%s*[%w_.]*%.Group%(\"([^\"]+)\"")
        if group_var and path then
          table.insert(group_stack, {var = group_var, path = path})
        end
      end
    end

    -- Extract base paths
    for _, group in ipairs(group_stack) do
      table.insert(base_paths, group.path)
    end

    return base_paths
  end
}

local gin = interface.create_hybrid_framework(config, detection, patterns, context_analyzer)

function gin.parse_line(line, method)
  local file_path, line_number, column, content = line:match("([^:]+):(%d+):(%d+):(.*)")
  if not content then return nil end

  -- Extract method and path from Gin patterns
  local http_method, path = gin.extract_route_info(content, method, file_path, tonumber(line_number))
  if not http_method or not path then return nil end

  return {
    method = http_method,
    endpoint_path = path,
    file_path = file_path,
    line_number = tonumber(line_number),
    column = tonumber(column),
    display_value = http_method .. " " .. path,
  }
end

function gin.extract_route_info(content, search_method, file_path, line_number)
  -- Pattern 1: router.GET("/path", handler)
  local method, path = content:match("%.(%w+)%(\"([^\"]+)\"")
  if method and path then
    -- Get context for full path
    local context = gin.analyze_context(file_path, line_number)
    local full_path = table.concat(context, "") .. path
    return method:upper(), full_path
  end

  -- Pattern 2: r.GET("/path", handler) - with route groups
  method, path = content:match("r%.(%w+)%(\"([^\"]+)\"")
  if method and path then
    local context = gin.analyze_context(file_path, line_number)
    local full_path = table.concat(context, "") .. path
    return method:upper(), full_path
  end

  return nil, nil
end

local factory = require("endpoint.core.framework_factory")
factory.register_framework("gin", gin)
return gin
```

### 🟨 JavaScript Express (Simple)

```lua
-- file: ~/.config/nvim/lua/endpoint/frameworks/express_enhanced.lua
local factory = require("endpoint.core.framework_factory")

local express = factory.create_quick_pattern_framework({
  name = "express_enhanced",
  file_extensions = {"*.js", "*.ts", "*.mjs"},
  patterns = {
    GET = {
      "app\\.get\\(",
      "router\\.get\\(",
      "express\\(\\)%.get\\(",
      "\\.get\\(",
    },
    POST = {
      "app\\.post\\(",
      "router\\.post\\(",
      "express\\(\\)%.post\\(",
      "\\.post\\(",
    },
    PUT = {
      "app\\.put\\(",
      "router\\.put\\(",
      "express\\(\\)%.put\\(",
      "\\.put\\(",
    },
    DELETE = {
      "app\\.delete\\(",
      "router\\.delete\\(",
      "express\\(\\)%.delete\\(",
      "\\.delete\\(",
    },
    PATCH = {
      "app\\.patch\\(",
      "router\\.patch\\(",
      "express\\(\\)%.patch\\(",
      "\\.patch\\(",
    },
    ALL = {
      "(app|router|express\\(\\))\\.(get|post|put|delete|patch)\\(",
      "\\.(get|post|put|delete|patch)\\(",
    },
  },
  dependencies = {"express"},
  files = {"package.json"},
  exclude_patterns = {"node_modules", "dist", "build"},
})

function express.extract_route_info(content, search_method)
  -- Pattern 1: app.get('/path', handler)
  local method, path = content:match("app%.(%w+)%(.-['\"]([^'\"]+)['\"]")
  if method and path then
    return method:upper(), path
  end

  -- Pattern 2: router.get('/path', handler)
  method, path = content:match("router%.(%w+)%(.-['\"]([^'\"]+)['\"]")
  if method and path then
    return method:upper(), path
  end

  -- Pattern 3: express().get('/path', handler)
  method, path = content:match("express%(%)[.](%w+)%(.-['\"]([^'\"]+)['\"]")
  if method and path then
    return method:upper(), path
  end

  return nil, nil
end

local factory = require("endpoint.core.framework_factory")
factory.register_framework("express_enhanced", express)
return express
```

### 🦙 Python Flask

```lua
-- file: ~/.config/nvim/lua/endpoint/frameworks/flask.lua
local factory = require("endpoint.core.framework_factory")

local flask = factory.create_quick_pattern_framework({
  name = "flask",
  file_extensions = {"*.py"},
  patterns = {
    GET = {
      "@app\\.route\\(.*methods.*GET",
      "@app\\.get\\(",
      "@bp\\.route\\(.*methods.*GET",
      "@blueprint\\.route\\(.*methods.*GET",
    },
    POST = {
      "@app\\.route\\(.*methods.*POST",
      "@app\\.post\\(",
      "@bp\\.route\\(.*methods.*POST",
      "@blueprint\\.route\\(.*methods.*POST",
    },
    PUT = {
      "@app\\.route\\(.*methods.*PUT",
      "@app\\.put\\(",
      "@bp\\.route\\(.*methods.*PUT",
      "@blueprint\\.route\\(.*methods.*PUT",
    },
    DELETE = {
      "@app\\.route\\(.*methods.*DELETE",
      "@app\\.delete\\(",
      "@bp\\.route\\(.*methods.*DELETE",
      "@blueprint\\.route\\(.*methods.*DELETE",
    },
    ALL = {
      "@app\\.route\\(",
      "@app\\.(get|post|put|delete|patch)\\(",
      "@bp\\.route\\(",
      "@blueprint\\.route\\(",
    },
  },
  dependencies = {"flask", "Flask"},
  files = {"app.py", "wsgi.py", "requirements.txt"},
  exclude_patterns = {"venv", "env", "__pycache__", ".pytest_cache"},
})

function flask.extract_route_info(content, search_method)
  -- Pattern 1: @app.route('/path', methods=['GET'])
  local path = content:match("@app%.route%(.-['\"]([^'\"]+)['\"]")
  if path then
    local methods_str = content:match("methods%s*=%s*%[([^%]]+)%]")
    if methods_str then
      local method = methods_str:match("['\"]([^'\"]+)['\"]")
      if method then
        return method:upper(), path
      end
    end
    return "GET", path -- Default to GET if no methods specified
  end

  -- Pattern 2: @app.get('/path')
  path = content:match("@app%.get%(.-['\"]([^'\"]+)['\"]")
  if path then
    return "GET", path
  end

  -- Similar for other methods...
  path = content:match("@app%.post%(.-['\"]([^'\"]+)['\"]")
  if path then
    return "POST", path
  end

  return nil, nil
end

local factory = require("endpoint.core.framework_factory")
factory.register_framework("flask", flask)
return flask
```

## Testing Framework Implementations

### Basic Test Structure

```lua
-- file: tests/frameworks/test_laravel.lua
local laravel = require("endpoint.frameworks.laravel")

describe("Laravel framework", function()
  it("should detect Laravel projects", function()
    -- Mock file system
    vim.fn.filereadable = function(file)
      return file == "artisan" and 1 or 0
    end

    assert.is_true(laravel.detect())
  end)

  it("should parse Route::get patterns", function()
    local line = "app/routes/web.php:15:1:Route::get('/users', 'UserController@index');"
    local result = laravel.parse_line(line, "GET")

    assert.is_not_nil(result)
    assert.equals("GET", result.method)
    assert.equals("/users", result.endpoint_path)
    assert.equals("app/routes/web.php", result.file_path)
    assert.equals(15, result.line_number)
  end)

  it("should extract route info correctly", function()
    local content = "Route::get('/api/users/{id}', 'UserController@show');"
    local method, path = laravel.extract_route_info(content, "GET")

    assert.equals("GET", method)
    assert.equals("/api/users/{id}", path)
  end)
end)
```

## User Configuration Examples

### Loading Custom Frameworks

```lua
-- file: ~/.config/nvim/lua/endpoint_config.lua
local factory = require("endpoint.core.framework_factory")

-- Load custom frameworks from user config
local function load_custom_frameworks()
  local custom_frameworks = {
    -- Custom PHP framework
    {
      name = "symfony",
      file_extensions = {"*.php"},
      patterns = {
        GET = {"@Route.*methods.*GET", "#\\[Route.*methods.*GET\\]"},
        POST = {"@Route.*methods.*POST", "#\\[Route.*methods.*POST\\]"},
        ALL = {"@Route", "#\\[Route"},
      },
      dependencies = {"symfony/framework-bundle"},
      files = {"symfony.lock", "composer.json"},
    },

    -- Custom Go framework
    {
      name = "fiber",
      file_extensions = {"*.go"},
      patterns = {
        GET = {"app\\.Get\\(", "router\\.Get\\("},
        POST = {"app\\.Post\\(", "router\\.Post\\("},
        ALL = {"app\\.(Get|Post|Put|Delete)\\("},
      },
      dependencies = {"github.com/gofiber/fiber"},
      files = {"go.mod"},
    },
  }

  -- Register all custom frameworks
  for _, config in ipairs(custom_frameworks) do
    local framework = factory.create_quick_pattern_framework(config)
    factory.register_framework(config.name, framework)
  end
end

-- Load frameworks when plugin starts
load_custom_frameworks()
```

### Framework Priority System

```lua
-- file: ~/.config/nvim/lua/endpoint_priority.lua
local factory = require("endpoint.core.framework_factory")

-- Override detection to prioritize certain frameworks
local original_detect = factory.detect_framework

function factory.detect_framework()
  -- Check high-priority frameworks first
  local priority_frameworks = {"django", "laravel", "gin", "actix_web"}

  for _, name in ipairs(priority_frameworks) do
    local framework = factory.get_framework(name)
    if framework and framework.detect() then
      return framework, name
    end
  end

  -- Fall back to original detection
  return original_detect()
end
```

These examples show how the new framework system makes it incredibly easy to add support for any web framework. The pattern-based approach works for most frameworks, while the hybrid strategy can handle more complex routing scenarios.