---@class endpoint.test.framework_helpers
local M = {}

-- Common test setup that most framework tests need
function M.setup_package_path()
  if _G.original_package_path then
    package.path = _G.original_package_path
  end
end

-- Test framework detection with fixture
---@param framework_module table The framework module to test
---@param framework_name string Name of the framework (e.g., "spring", "servlet")
---@param should_detect boolean|nil Whether detection should succeed (default: true)
function M.test_framework_detection_with_fixture(framework_module, framework_name, should_detect)
  if should_detect == nil then
    should_detect = true
  end

  local fixture_path = "tests/fixtures/" .. framework_name
  if vim.fn.isdirectory(fixture_path) == 1 then
    local original_cwd = vim.fn.getcwd()
    vim.fn.chdir(fixture_path)
    M.setup_package_path()

    local detected = framework_module.detect()
    if should_detect then
      assert.is_true(detected)
    else
      assert.is_false(detected)
    end

    vim.fn.chdir(original_cwd)
  else
    pending(string.format("%s fixture directory not found", framework_name:gsub("^%l", string.upper)))
  end
end

-- Test framework should not detect in empty directory
---@param framework_module table The framework module to test
---@param framework_name string Name of the framework for temp directory naming
function M.test_framework_non_detection(framework_module, framework_name)
  local temp_dir = "/tmp/non_" .. framework_name .. "_" .. os.time()
  vim.fn.mkdir(temp_dir, "p")
  local original_cwd = vim.fn.getcwd()
  vim.fn.chdir(temp_dir)
  M.setup_package_path()

  local detected = framework_module.detect()
  assert.is_false(detected)

  vim.fn.chdir(original_cwd)
  vim.fn.delete(temp_dir, "rf")
end

-- Test search command generation for a specific HTTP method
---@param framework_module table The framework module to test
---@param method string HTTP method (GET, POST, etc.)
---@param expected_patterns string[] Optional patterns that should be in the command
function M.test_search_cmd_generation(framework_module, method, expected_patterns)
  local cmd = framework_module.get_search_cmd(method)
  assert.is_string(cmd)
  assert.is_true(cmd:match "rg" ~= nil, "Search command should contain 'rg'")

  if expected_patterns then
    for _, pattern in ipairs(expected_patterns) do
      assert.is_true(cmd:match(pattern) ~= nil, string.format("Search command should contain pattern: %s", pattern))
    end
  end
end

-- Test basic line parsing functionality
---@param framework_module table The framework module to test
---@param test_line string Sample line to parse
---@param method string Expected HTTP method
---@param expected table Expected result fields
function M.test_basic_line_parsing(framework_module, test_line, method, expected)
  local result = framework_module.parse_line(test_line, method)

  assert.is_not_nil(result)
  assert.is_table(result, "parse_line should return a table")

  if expected.method then
    assert.are.equal(expected.method, result and result.method)
  end
  if expected.endpoint_path then
    assert.are.equal(expected.endpoint_path, result and result.endpoint_path)
  end
  if expected.file_path then
    assert.are.equal(expected.file_path, result and result.file_path)
  end
  if expected.line_number then
    assert.are.equal(expected.line_number, result and result.line_number)
  end
  if expected.column then
    assert.are.equal(expected.column, result and result.column)
  end
end

-- Test that invalid lines return nil
---@param framework_module table The framework module to test
function M.test_invalid_line_parsing(framework_module)
  local invalid_cases = {
    "invalid line format",
    "",
    nil,
  }

  for _, invalid_line in ipairs(invalid_cases) do
    local result = framework_module.parse_line(invalid_line, "GET")
    assert.is_nil(result, string.format("Should return nil for invalid line: %s", invalid_line or "nil"))
  end
end

-- Test integration with fixture files
---@param framework_module table The framework module to test
---@param framework_name string Name of the framework
---@param additional_checks function|nil Optional additional checks to perform
function M.test_integration_with_fixtures(framework_module, framework_name, additional_checks)
  local fixture_path = "tests/fixtures/" .. framework_name
  if vim.fn.isdirectory(fixture_path) == 1 then
    local original_cwd = vim.fn.getcwd()
    vim.fn.chdir(fixture_path)
    M.setup_package_path()

    -- Test that framework is detected
    assert.is_true(framework_module.detect())

    -- Test that search command works
    local cmd = framework_module.get_search_cmd "GET"
    assert.is_string(cmd)

    -- Run additional checks if provided
    if additional_checks then
      additional_checks(framework_module)
    end

    vim.fn.chdir(original_cwd)
  else
    pending(string.format("%s fixture directory not found", framework_name:gsub("^%l", string.upper)))
  end
end

-- Create a standard framework detection test suite
---@param framework_module table The framework module to test
---@param framework_name string Name of the framework
---@return function The test suite function
function M.create_detection_test_suite(framework_module, framework_name)
  return function()
    it(string.format("should detect %s project", framework_name:gsub("^%l", string.upper)), function()
      M.test_framework_detection_with_fixture(framework_module, framework_name)
    end)

    it(
      string.format(
        "should not detect %s in non-%s directory",
        framework_name:gsub("^%l", string.upper),
        framework_name
      ),
      function()
        M.test_framework_non_detection(framework_module, framework_name)
      end
    )
  end
end

-- Create a standard search command test suite
---@param framework_module table The framework module to test
---@param method_patterns table Map of method -> expected patterns
---@return function The test suite function
function M.create_search_cmd_test_suite(framework_module, method_patterns)
  return function()
    local methods = { "GET", "POST", "PUT", "DELETE", "PATCH", "ALL" }

    for _, method in ipairs(methods) do
      it(string.format("should generate search command for %s method", method), function()
        local expected = method_patterns and method_patterns[method]
        M.test_search_cmd_generation(framework_module, method, expected)
      end)
    end
  end
end

-- Create a standard line parsing test suite
---@param framework_module table The framework module to test
---@param test_cases table Array of test cases {line, method, expected}
---@return function The test suite function
function M.create_line_parsing_test_suite(framework_module, test_cases)
  return function()
    for i, test_case in ipairs(test_cases) do
      local line, method, expected = test_case.line, test_case.method, test_case.expected
      local description = test_case.description or string.format("test case %d", i)

      it(description, function()
        M.test_basic_line_parsing(framework_module, line, method, expected)
      end)
    end

    it("should return nil for invalid lines", function()
      M.test_invalid_line_parsing(framework_module)
    end)

    it("should return nil for empty lines", function()
      local result = framework_module.parse_line("", "GET")
      assert.is_nil(result)
    end)
  end
end

-- Create a standard integration test suite
---@param framework_module table The framework module to test
---@param framework_name string Name of the framework
---@param additional_checks function|nil Optional additional checks
---@return function The test suite function
function M.create_integration_test_suite(framework_module, framework_name, additional_checks)
  return function()
    it(
      string.format("should correctly parse real %s fixture files", framework_name:gsub("^%l", string.upper)),
      function()
        M.test_integration_with_fixtures(framework_module, framework_name, additional_checks)
      end
    )
  end
end

return M

