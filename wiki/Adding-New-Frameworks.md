# Adding New Frameworks

Complete guide for implementing support for new web frameworks in endpoint.nvim.

## Framework Architecture

Each framework is implemented as a separate Lua module in `lua/endpoint/frameworks/` that implements three core functions:

```lua
local M = {}

-- Framework detection
function M.detect()
  -- Return true if framework is detected in current directory
end

-- Generate search command for method
function M.get_search_cmd(method)
  -- Return ripgrep command to find endpoints
end

-- Parse search results
function M.parse_line(line, method)
  -- Parse ripgrep output line and return endpoint data
end

return M
```

## Implementation Steps

### 1. Create Framework Module

Create `lua/endpoint/frameworks/yourframework.lua`:

```lua
---@class endpoint.frameworks.yourframework
local M = {}

local fs = require "endpoint.utils.fs"

-- Detection
---@return boolean
function M.detect()
  -- Check for framework-specific files
  local has_config = fs.has_file {
    "yourframework.config",
    "package.json", -- if web framework
  }

  local has_code = vim.fn
    .system("find . -name '*.ext' -exec grep -l '@YourAnnotation\\|yourPatterns' {} \\; 2>/dev/null")
    :match "%S" ~= nil

  return has_config and has_code
end

-- Create search command generator using utility function
local search_utils = require "endpoint.utils.search"
local get_search_cmd = search_utils.create_search_cmd_generator(
  {
    GET = { "@get", "get\\(" },
    POST = { "@post", "post\\(" },
    PUT = { "@put", "put\\(" },
    DELETE = { "@delete", "delete\\(" },
    PATCH = { "@patch", "patch\\(" },
    ALL = { "@get", "@post", "@put", "@delete", "@patch", "get\\(", "post\\(" },
  },
  { "**/*.ext" }, -- File patterns
  { "**/build", "**/dist" }, -- Exclude patterns
  { "--case-sensitive" } -- Additional ripgrep flags
)

-- Search command generation
---@param method string
---@return string
function M.get_search_cmd(method)
  return get_search_cmd(method)
end

-- Parse ripgrep output line
---@param line string
---@param method string
---@return endpoint.entry?
function M.parse_line(line, method)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    return nil
  end

  -- Extract HTTP method and path from your framework patterns
  local http_method, endpoint_path = M.extract_route_info(content, method)
  if not http_method or not endpoint_path then
    return nil
  end

  return {
    method = http_method,
    endpoint_path = endpoint_path,
    file_path = file_path,
    line_number = tonumber(line_number),
    column = tonumber(column),
    display_value = http_method .. " " .. endpoint_path,
  }
end

-- Extract route information from your framework patterns
---@param content string
---@param search_method string
---@return string?, string?
function M.extract_route_info(content, search_method)
  -- Pattern 1: @Get("/path")
  local method, path = content:match '@(%w+)%(["\']([^"\']+)["\']'
  if method and path then
    return method:upper(), path
  end

  -- Pattern 2: yourFramework.get("/path", handler)
  method, path = content:match 'yourFramework%.(%w+)%(["\']([^"\']+)["\']'
  if method and path then
    return method:upper(), path
  end

  -- Add more patterns as needed...

  return nil, nil
end

return M
```

### 2. Register Framework

Add your framework to `lua/endpoint/scanner.lua`:

```lua
-- Available frameworks
local frameworks = {
  spring = require "endpoint.frameworks.spring",
  nestjs = require "endpoint.frameworks.nestjs",
  yourframework = require "endpoint.frameworks.yourframework", -- Add here
}
```

### 3. Create Test Fixtures

Create realistic sample project in `tests/fixtures/yourframework/`:

```text
tests/fixtures/yourframework/
├── yourframework.config
├── package.json (if applicable)
├── src/
│   ├── controllers/
│   │   ├── UserController.ext
│   │   ├── ProductController.ext
│   │   └── OrderController.ext
│   └── routes/
│       └── api.ext
└── README.md
```

Example controller file:
```ext
@Controller("/api/users")
class UserController {
    @Get("/")
    getAllUsers() { ... }

    @Get("/{id}")
    getUser(id) { ... }

    @Post("/")
    createUser(data) { ... }

    @Put("/{id}")
    updateUser(id, data) { ... }

    @Delete("/{id}")
    deleteUser(id) { ... }
}
```

### 4. Write Tests

Create `tests/spec/yourframework_spec.lua`:

```lua
describe("YourFramework framework", function()
  local test_helpers = require "tests.utils.framework_test_helpers"
  local yourframework = require "endpoint.frameworks.yourframework"

  describe("framework detection", test_helpers.create_detection_test_suite(yourframework, "yourframework"))

  describe(
    "search command generation",
    test_helpers.create_search_cmd_test_suite(yourframework, {
      GET = { "@get", "get\\(" },
      POST = { "@post", "post\\(" },
      PUT = { "@put", "put\\(" },
      DELETE = { "@delete", "delete\\(" },
      PATCH = { "@patch", "patch\\(" },
      ALL = { "@get", "@post", "get\\(", "post\\(" },
    })
  )

  describe(
    "line parsing",
    test_helpers.create_line_parsing_test_suite(yourframework, {
      {
        description = "should parse @Get annotation",
        line = 'tests/fixtures/yourframework/src/UserController.ext:10:5:    @Get("/users")',
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/users/users", -- With controller base path
          file_path = "tests/fixtures/yourframework/src/UserController.ext",
          line_number = 10,
          column = 5,
        },
      },
      {
        description = "should parse framework.get() method",
        line = 'tests/fixtures/yourframework/src/api.ext:15:1:yourframework.get("/health", handler)',
        method = "GET",
        expected = {
          method = "GET", 
          endpoint_path = "/health",
          file_path = "tests/fixtures/yourframework/src/api.ext",
          line_number = 15,
          column = 1,
        },
      },
    })
  )

  describe(
    "integration with fixtures",
    test_helpers.create_integration_test_suite(yourframework, "yourframework")
  )
end)
```

### 5. Add Test Target

Add to `Makefile`:

```makefile
test-yourframework:
	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedFile tests/spec/yourframework_spec.lua"

# Update framework test target
test-frameworks: test-spring test-nestjs test-yourframework
	@echo "Framework tests completed"
```

## Common Patterns

### Framework Detection

```lua
function M.detect()
  -- Method 1: Check for specific config files
  local has_config = fs.has_file {
    "yourframework.json",
    "yourframework.yml",
  }

  -- Method 2: Check for dependencies in package.json/composer.json/etc
  local has_deps = fs.file_contains("package.json", {
    "yourframework",
    "@yourframework/core",
  })

  -- Method 3: Check for code patterns
  local has_code = vim.fn
    .system("find . -name '*.ext' -exec grep -l '@YourAnnotation' {} \\; 2>/dev/null")
    :match "%S" ~= nil

  return has_config or (has_deps and has_code)
end
```

### Search Patterns

```lua
-- Simple patterns
local patterns = {
  GET = { "@Get", "get\\(" },
  POST = { "@Post", "post\\(" },
  -- ...
}

-- Complex patterns with variations
local patterns = {
  GET = { 
    "@Get",           -- @Get("/path")
    "@GetMapping",    -- @GetMapping("/path") 
    "get\\(",         -- framework.get("/path")
    "\\.get\\(",      -- router.get("/path")
  },
  -- ...
}
```

### Route Extraction

```lua
function M.extract_route_info(content, search_method)
  -- Pattern 1: Annotation with path
  local method, path = content:match '@(%w+)%(["\']([^"\']+)["\']'
  if method and path then
    return method:upper(), path
  end

  -- Pattern 2: Method call with path
  method, path = content:match '%.(%w+)%(["\']([^"\']+)["\']'
  if method and path then
    return method:upper(), path
  end

  -- Pattern 3: Annotation without path (use class-level routing)
  method = content:match '@(%w+)%s*$'
  if method then
    local base_path = get_controller_base_path(file_path)
    return method:upper(), base_path
  end

  return nil, nil
end
```

## Testing Your Implementation

### Manual Testing

```bash
# 1. Test framework detection
cd tests/fixtures/yourframework
nvim -c "lua print('Detected:', require('endpoint.frameworks.yourframework').detect())" -c "qa"

# 2. Test search command
nvim -c "lua print('Search cmd:', require('endpoint.frameworks.yourframework').get_search_cmd('GET'))" -c "qa"

# 3. Test line parsing
nvim -c "lua 
local result = require('endpoint.frameworks.yourframework').parse_line('src/Controller.ext:10:5:@Get(\"/test\")', 'GET')
print('Parsed:', vim.inspect(result))
" -c "qa"

# 4. Run framework tests
make test-yourframework
```

### Integration Testing

```bash
# Test with actual project
cd /path/to/real/yourframework/project
nvim -c "Endpoint All"
```

## Examples from Existing Frameworks

### Simple Framework (FastAPI)
- File patterns: `**/*.py`
- Patterns: `@app.get`, `@router.post`
- No complex base path logic

### Complex Framework (Spring Boot)
- File patterns: `**/*.java`
- Patterns: `@GetMapping`, `@RequestMapping`
- Controller-level `@RequestMapping` base paths
- Method-level path combination

### Modern Framework (.NET Core)
- Multiple routing styles: Controllers, Minimal API, Endpoint routing
- Token replacement: `[controller]` → `users`
- Route constraints: `{id:int}`

## Troubleshooting

### Common Issues

1. **Framework not detected**:
   - Check `detect()` function logic
   - Verify fixture files exist
   - Test in actual project directory

2. **No endpoints found**:
   - Test ripgrep command manually
   - Check file glob patterns
   - Verify regex patterns match your framework's syntax

3. **Parsing failures**:
   - Test `parse_line()` with real output
   - Check regex capture groups
   - Handle edge cases (no path, different quote styles)

4. **Path resolution issues**:
   - Implement base path extraction if needed
   - Handle relative vs absolute paths
   - Test with nested routing structures

### Debug Output

Enable debug mode to see detailed information:

```bash
ENDPOINT_DEBUG=1 nvim -c "Endpoint All"
```

This will show:
- Framework detection results
- Generated search commands
- Raw ripgrep output
- Parsed endpoint data