# Contributing to endpoint.nvim

> **Welcome contributors!** 🎉
> This guide helps you contribute new framework support, bug fixes, and features.

## Table of Contents

- [Quick Start](#quick-start)
- [Adding Framework Support](#adding-framework-support)
- [Development Setup](#development-setup)
- [Testing](#testing)
- [Code Standards](#code-standards)
- [Submission Guidelines](#submission-guidelines)

---

## Quick Start

### 🚀 Adding a New Framework (5 minutes)

The easiest way to contribute is by adding support for a new web framework:

```bash
# 1. Fork and clone the repository
git clone https://github.com/yourusername/endpoint.nvim
cd endpoint.nvim

# 2. Create a new branch
git checkout -b add-laravel-support

# 3. Create the framework file
mkdir -p lua/endpoint/frameworks
# See examples below
```

### Framework Contribution Checklist

- [ ] **Framework detection** works correctly
- [ ] **Route patterns** cover common use cases
- [ ] **Parse logic** extracts endpoints accurately
- [ ] **Tests** cover main functionality
- [ ] **Documentation** includes usage examples
- [ ] **No breaking changes** to existing functionality

---

## Adding Framework Support

### Method 1: Template Generation (Recommended)

```lua
-- Create config for your framework
local templates = require("endpoint.core.framework_templates")
local strategies = require("endpoint.core.strategies")

local laravel_config = {
  framework_name = "laravel",
  language = "php",
  strategy = strategies.STRATEGY_TYPES.PATTERN_MATCHING,
  file_extensions = {"*.php"},
  route_patterns = {
    GET = {"Route::get\\(", "->get\\("},
    POST = {"Route::post\\(", "->post\\("},
    -- ... more patterns
    ALL = {"Route::(get|post|put|delete)\\("},
  },
  detection_files = {"artisan", "composer.json"},
  dependencies = {"laravel/framework"},
  exclude_dirs = {"vendor", "storage"},
}

-- Generate the framework file
templates.create_framework_file(laravel_config, "lua/endpoint/frameworks/laravel.lua")
```

### Method 2: Manual Implementation

```lua
-- lua/endpoint/frameworks/yourframework.lua
local factory = require("endpoint.core.framework_factory")

local yourframework = factory.create_quick_pattern_framework({
  name = "yourframework",
  file_extensions = {"*.ext"},
  patterns = {
    GET = {"pattern_for_get"},
    POST = {"pattern_for_post"},
    ALL = {"pattern_for_all"},
  },
  dependencies = {"your-framework"},
  files = {"framework.config"},
})

-- Custom parsing logic
function yourframework.extract_route_info(content, search_method)
  -- Your custom parsing logic here
  local method, path = extract_from_content(content)
  return method, path
end

factory.register_framework("yourframework", yourframework)
return yourframework
```

### Framework Strategy Selection

Choose the right strategy for your framework:

| Strategy | Best For | Examples |
|----------|----------|----------|
| `PATTERN_MATCHING` | Annotation/decorator based | Spring Boot, ASP.NET, FastAPI |
| `COMPREHENSIVE` | Complex routing structures | Django, Rails |
| `HYBRID` | Pattern + context analysis | Ktor, NestJS |

---

## Development Setup

### Prerequisites

- Neovim 0.8+
- Lua 5.1+
- `ripgrep` for search functionality

### Local Development

```bash
# Clone repository
git clone https://github.com/anthropics/endpoint.nvim
cd endpoint.nvim

# Install development dependencies (if using luarocks)
luarocks install busted  # for testing
luarocks install luacheck  # for linting

# Run tests
busted tests/

# Check code quality
luacheck lua/
```

### Testing Your Framework

```lua
-- Test detection
local framework = require("endpoint.frameworks.yourframework")
print("Detection works:", framework.detect())

-- Test search command
print("Search command:", framework.get_search_cmd("GET"))

-- Test parsing
local test_line = "file.ext:10:1:your_route_pattern('/path')"
local result = framework.parse_line(test_line, "GET")
print("Parse result:", vim.inspect(result))
```

---

## Testing

### Test Structure

```
tests/
├── frameworks/
│   ├── test_django.lua
│   ├── test_spring.lua
│   └── test_yourframework.lua
├── core/
│   ├── test_factory.lua
│   └── test_strategies.lua
└── fixtures/
    └── sample_projects/
```

### Writing Framework Tests

```lua
-- tests/frameworks/test_yourframework.lua
local yourframework = require("endpoint.frameworks.yourframework")

describe("YourFramework", function()
  describe("detection", function()
    it("detects framework when config file exists", function()
      -- Mock filesystem
      vim.fn.filereadable = function(file)
        return file == "framework.config" and 1 or 0
      end

      assert.is_true(yourframework.detect())
    end)
  end)

  describe("parsing", function()
    it("parses route patterns correctly", function()
      local line = "app.ext:15:1:route.get('/api/users', handler)"
      local result = yourframework.parse_line(line, "GET")

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/api/users", result.endpoint_path)
      assert.equals("app.ext", result.file_path)
      assert.equals(15, result.line_number)
    end)

    it("handles parameters in routes", function()
      local content = "route.get('/users/{id}', handler)"
      local method, path = yourframework.extract_route_info(content, "GET")

      assert.equals("GET", method)
      assert.equals("/users/{id}", path)
    end)
  end)
end)
```

### Running Tests

```bash
# Run all tests
busted

# Run specific framework tests
busted tests/frameworks/test_yourframework.lua

# Run with coverage
busted --coverage

# Test against real projects
cd tests/fixtures/your_framework_project
nvim -c "lua require('endpoint').scan('ALL')"
```

---

## Code Standards

### Lua Style Guide

- **Indentation**: 2 spaces
- **Line length**: 100 characters max
- **Naming**: `snake_case` for variables, `PascalCase` for classes
- **Comments**: Use `---@` annotations for functions

```lua
-- Good
---@param method string HTTP method
---@return endpoint.entry[] List of endpoints
local function scan_endpoints(method)
  local results = {}
  -- Implementation here
  return results
end

-- Bad
function scanEndpoints(method)  -- Wrong naming
    local Results = {}          -- Wrong indentation, naming
    return Results
end
```

### Documentation Standards

- All public functions must have `---@` annotations
- Include usage examples in docstrings
- Update README.md for new frameworks
- Add entries to framework examples

### Error Handling

```lua
-- Good: Handle errors gracefully
local function safe_file_read(file_path)
  if vim.fn.filereadable(file_path) ~= 1 then
    return nil
  end

  local success, content = pcall(vim.fn.readfile, file_path)
  return success and content or nil
end

-- Bad: Let errors crash
local function unsafe_read(file_path)
  return vim.fn.readfile(file_path)  -- Will crash if file doesn't exist
end
```

---

## Submission Guidelines

### Before Submitting

1. **Test thoroughly**: Run tests and verify with real projects
2. **Check code quality**: No linting errors
3. **Update documentation**: Add examples and usage notes
4. **Verify backwards compatibility**: Existing frameworks still work

### Pull Request Process

1. **Create descriptive title**: "Add Laravel framework support"
2. **Include framework info**:
   ```
   ## Framework: Laravel (PHP)
   - Strategy: Pattern Matching
   - File types: *.php
   - Key patterns: Route::get(), ->get()
   - Detection: artisan, composer.json
   ```

3. **Provide test cases**: Show it works with real projects
4. **Screenshots**: Include examples of endpoint discovery

### PR Template

```markdown
## Framework Addition: [Framework Name]

### Framework Details
- **Language**: [e.g., PHP, Go, Rust]
- **Framework**: [e.g., Laravel, Gin, Actix Web]
- **Strategy**: [PATTERN_MATCHING/COMPREHENSIVE/HYBRID]
- **Homepage**: [Framework URL]

### Implementation
- [ ] Detection logic implemented
- [ ] Route patterns defined
- [ ] Parse logic working
- [ ] Tests added and passing
- [ ] Documentation updated

### Testing
Tested with these projects:
- [ ] [Project name/repo] - [working/issues]
- [ ] [Another project] - [working/issues]

### Examples
```lua
-- Example route definitions that should be detected
Route::get('/api/users', 'UserController@index');
Route::post('/api/users', 'UserController@store');
```

### Screenshots
[Include screenshots showing endpoint discovery working]
```

### Review Process

1. **Automated checks**: CI tests must pass
2. **Manual review**: Maintainer reviews implementation
3. **Integration testing**: Test with various projects
4. **Documentation review**: Examples and guides checked
5. **Merge**: Added to main branch and included in next release

---

## Common Issues & Solutions

### Framework Not Detected

- **Issue**: Framework detection returns false
- **Solution**: Check detection files and dependencies patterns
- **Debug**: Add `print()` statements in detection logic

### Routes Not Found

- **Issue**: Search patterns don't match route definitions
- **Solution**: Test regex patterns with actual code examples
- **Debug**: Run search command manually with `rg`

### Incorrect Parsing

- **Issue**: Route paths or methods parsed incorrectly
- **Solution**: Check pattern matching in `extract_route_info`
- **Debug**: Print `content` variable to see what's being parsed

### Performance Issues

- **Issue**: Slow endpoint discovery
- **Solution**: Optimize patterns, add exclude directories
- **Debug**: Use `time` command to measure search performance

---

## Getting Help

### Community

- **GitHub Issues**: [Report bugs or ask questions](https://github.com/anthropics/endpoint.nvim/issues)
- **Discussions**: [General discussion and help](https://github.com/anthropics/endpoint.nvim/discussions)

### Development Resources

- **Framework Examples**: See `docs/framework-examples.md`
- **API Reference**: Check `lua/endpoint/core/` modules
- **Test Examples**: Look at existing framework tests

### Maintainer Contact

- Create an issue for bugs or feature requests
- Use discussions for general questions
- Tag `@maintainer` in PRs for review

---

## Recognition

Contributors will be:
- Added to `CONTRIBUTORS.md`
- Mentioned in release notes
- Added as framework maintainer (for substantial contributions)

**Thank you for contributing to endpoint.nvim!** 🎉

---

*Happy contributing! Your framework support helps developers worldwide navigate their codebases more efficiently.*