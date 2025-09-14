# Development & Testing

Complete guide for developing and testing endpoint.nvim.

## Development Setup

### Prerequisites

```bash
# Required tools
git clone https://github.com/zerochae/endpoint.nvim.git
cd endpoint.nvim

# Test dependencies (automatically installed by tests/minit.lua)
# - plenary.nvim
# - telescope.nvim
```

## Running Tests

### Test Commands

```bash
# Run all tests
make test

# Test specific frameworks
make test-frameworks  # All framework tests together
make test-spring      # Spring Boot tests only
make test-nestjs      # NestJS tests only
make test-dotnet      # .NET Core tests only
make test-rails       # Rails tests only
make test-fastapi     # FastAPI tests only
make test-symfony     # Symfony tests only
make test-express     # Express tests only
make test-ktor        # Ktor tests only

# Test specific components
make test-cache       # Cache functionality tests
make test-pickers     # Picker interface tests
```

### Running Individual Tests

```bash
# Run single test file
nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedFile tests/spec/spring_spec.lua"

# Run with debug output
nvim --headless --noplugin -u tests/minit.lua -c "vim.g.endpoint_debug = true" -c "PlenaryBustedFile tests/spec/dotnet_spec.lua"
```

## Test Structure

```text
tests/
├── fixtures/              # Test fixture projects
│   ├── spring/            # Sample Spring Boot project
│   ├── nestjs/            # Sample NestJS project
│   ├── dotnet/            # Sample .NET Core project
│   ├── rails/             # Sample Rails project
│   └── [framework]/       # Other framework samples
├── spec/                  # Test specifications
│   ├── spring_spec.lua    # Spring Boot tests
│   ├── nestjs_spec.lua    # NestJS tests
│   ├── dotnet_spec.lua    # .NET Core tests
│   ├── cache_spec.lua     # Cache functionality tests
│   └── [framework]_spec.lua
├── utils/                 # Test utilities
│   └── framework_test_helpers.lua
└── minit.lua              # Test initialization
```

## Adding Tests

### Framework Tests

When adding a new framework or feature:

1. **Create test fixture**:
   ```bash
   mkdir tests/fixtures/your_framework
   # Add sample project files with various endpoint patterns
   ```

2. **Create test spec**:
   ```lua
   -- tests/spec/your_framework_spec.lua
   describe("Your Framework", function()
     local test_helpers = require "tests.utils.framework_test_helpers"
     local your_framework = require "endpoint.frameworks.your_framework"

     describe("framework detection", test_helpers.create_detection_test_suite(your_framework, "your_framework"))
     
     describe("line parsing", test_helpers.create_line_parsing_test_suite(your_framework, {
       {
         description = "should parse basic route",
         line = 'src/controller.ext:10:5:    @Get("/users")',
         method = "GET",
         expected = {
           method = "GET",
           endpoint_path = "/users",
           file_path = "src/controller.ext",
           line_number = 10,
           column = 5,
         },
       },
     }))
   end)
   ```

3. **Add to Makefile**:
   ```makefile
   test-your-framework:
   	nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedFile tests/spec/your_framework_spec.lua"
   ```

### Test Helpers

The `framework_test_helpers` module provides common test patterns:

```lua
local test_helpers = require "tests.utils.framework_test_helpers"

-- Framework detection tests
test_helpers.create_detection_test_suite(framework_module, "framework_name")

-- Search command generation tests  
test_helpers.create_search_cmd_test_suite(framework_module, {
  GET = { "expected_pattern1", "expected_pattern2" },
  POST = { "expected_pattern1" },
  -- ...
})

-- Line parsing tests
test_helpers.create_line_parsing_test_suite(framework_module, test_cases)

-- Integration tests
test_helpers.create_integration_test_suite(framework_module, "framework_name", custom_test_fn)
```

## Debugging Tests

### Debug Output

Enable debug mode for detailed output:

```bash
# Method 1: Environment variable
ENDPOINT_DEBUG=1 make test-spring

# Method 2: In test
nvim --headless --noplugin -u tests/minit.lua -c "vim.g.endpoint_debug = true" -c "PlenaryBustedFile tests/spec/spring_spec.lua"
```

### Validate Framework Detection

```bash
# Test framework detection in fixture directory
cd tests/fixtures/spring
nvim -c "lua print(require('endpoint.frameworks.spring').detect())" -c "qa"

# Check search command generation
nvim -c "lua print(require('endpoint.frameworks.spring').get_search_cmd('GET'))" -c "qa"
```

### Inspect Test Fixtures

```bash
# Check fixture structure
ls -la tests/fixtures/spring/src/main/java/com/example/

# Validate fixture content
cat tests/fixtures/spring/src/main/java/com/example/UserController.java
```

## Performance Testing

### Benchmark Cache Performance

```bash
# Test with large fixture projects
make test-cache

# Manual performance testing
cd tests/fixtures/spring
nvim -c "lua vim.g.endpoint_debug = true" -c "Endpoint All" -c "qa"
```

### Memory Usage

```bash
# Check memory usage during tests
nvim --headless --noplugin -u tests/minit.lua -c "
lua
local before = collectgarbage('count')
require('plenary.busted').run('tests/spec/')
local after = collectgarbage('count')
print('Memory used:', after - before, 'KB')
"
```

## Common Debugging Scenarios

### Test Failures

1. **Framework not detected**:
   - Check fixture directory has correct project files
   - Verify `detect()` function logic
   - Ensure working directory is correct

2. **Line parsing failures**:
   - Check ripgrep output format matches expected pattern
   - Verify regex patterns in `parse_line()`
   - Test with actual fixture files

3. **Search command issues**:
   - Test generated ripgrep commands manually
   - Check file glob patterns and exclusions
   - Verify regex escaping

### Test Environment Issues

```bash
# Clean test environment
rm -rf ~/.local/share/nvim/endpoint.nvim/

# Reset test dependencies
rm -rf tests/deps/
nvim --headless --noplugin -u tests/minit.lua -c "qa"
```

## Continuous Integration

The project uses GitHub Actions for CI. Local testing should match CI environment:

```bash
# Run full test suite (matches CI)
make test

# Check for any missed test files
find tests/spec/ -name "*.lua" | wc -l
grep -r "make test-" Makefile | wc -l
```