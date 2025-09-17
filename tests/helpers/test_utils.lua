-- Test Utilities for endpoint.nvim
-- Common helper functions for testing frameworks and strategies

local M = {}

---Creates a test file with specified content
---@param file_path string Full path to the test file
---@param content string Content to write to the file
function M.create_test_file(file_path, content)
  -- Ensure parent directory exists
  local parent_dir = vim.fn.fnamemodify(file_path, ":h")
  if vim.fn.isdirectory(parent_dir) == 0 then
    vim.fn.mkdir(parent_dir, "p")
  end

  -- Write content to file
  local lines = vim.split(content, "\n")
  vim.fn.writefile(lines, file_path)
end

---Validates endpoint structure against expected values
---@param endpoint table The parsed endpoint to validate
---@param expected table Expected values to check against
---@return boolean is_valid True if endpoint structure is valid
---@return string|nil error_message Error message if validation fails
function M.validate_endpoint_structure(endpoint, expected)
  if not endpoint then
    return false, "Endpoint is nil"
  end

  -- Check required fields
  local required_fields = {"method", "endpoint_path", "file_path", "line_number", "column", "display_value"}
  for _, field in ipairs(required_fields) do
    if endpoint[field] == nil then
      return false, string.format("Missing required field: %s", field)
    end
  end

  -- Check expected values if provided
  if expected then
    if expected.method and endpoint.method ~= expected.method then
      return false, string.format("Expected method %s, got %s", expected.method, endpoint.method)
    end

    if expected.path and endpoint.endpoint_path ~= expected.path then
      return false, string.format("Expected path %s, got %s", expected.path, endpoint.endpoint_path)
    end

    if expected.confidence and endpoint.confidence then
      if math.abs(endpoint.confidence - expected.confidence) > 0.1 then
        return false, string.format("Expected confidence ~%s, got %s", expected.confidence, endpoint.confidence)
      end
    end
  end

  -- Check metadata structure
  if endpoint.metadata then
    if type(endpoint.metadata) ~= "table" then
      return false, "Metadata should be a table"
    end
  end

  -- Check tags structure
  if endpoint.tags then
    if type(endpoint.tags) ~= "table" then
      return false, "Tags should be a table"
    end
  end

  return true, nil
end

---Creates a temporary directory for testing
---@return string temp_dir_path Path to the created temporary directory
function M.create_temp_directory()
  local temp_dir = vim.fn.tempname()
  vim.fn.mkdir(temp_dir, "p")
  return temp_dir
end

---Cleans up test files and directories
---@param paths string[] List of file/directory paths to clean up
function M.cleanup_test_files(paths)
  for _, path in ipairs(paths) do
    if vim.fn.filereadable(path) == 1 then
      vim.fn.delete(path)
    elseif vim.fn.isdirectory(path) == 1 then
      vim.fn.delete(path, "rf")
    end
  end
end

---Creates a mock file system utils for testing
---@param base_dir string Base directory for file operations
---@return table fs_utils Mock file system utilities
function M.create_mock_fs_utils(base_dir)
  return {
    has_file = function(file_spec)
      local file_path = file_spec[1] or file_spec
      local full_path = base_dir .. "/" .. file_path
      return vim.fn.filereadable(full_path) == 1
    end,

    file_contains = function(file_path, pattern)
      local full_path = base_dir .. "/" .. file_path
      if vim.fn.filereadable(full_path) == 0 then
        return false
      end

      local content = table.concat(vim.fn.readfile(full_path), "\n")
      return content:find(pattern, 1, true) ~= nil
    end,

    read_file = function(file_path)
      local full_path = base_dir .. "/" .. file_path
      if vim.fn.filereadable(full_path) == 0 then
        return nil
      end

      return table.concat(vim.fn.readfile(full_path), "\n")
    end,

    write_file = function(file_path, content)
      M.create_test_file(base_dir .. "/" .. file_path, content)
    end
  }
end

---Asserts that a value is not nil
---@param value any Value to check
---@param message string Error message if assertion fails
function M.assert_not_nil(value, message)
  if value == nil then
    error(message or "Expected value to not be nil")
  end
end

---Asserts that a value is nil
---@param value any Value to check
---@param message string Error message if assertion fails
function M.assert_nil(value, message)
  if value ~= nil then
    error(message or "Expected value to be nil")
  end
end

---Asserts that two values are equal
---@param expected any Expected value
---@param actual any Actual value
---@param message string Error message if assertion fails
function M.assert_equal(expected, actual, message)
  if expected ~= actual then
    error(message or string.format("Expected %s, got %s", tostring(expected), tostring(actual)))
  end
end

---Asserts that a condition is true
---@param condition boolean Condition to check
---@param message string Error message if assertion fails
function M.assert_true(condition, message)
  if not condition then
    error(message or "Expected condition to be true")
  end
end

---Asserts that a condition is false
---@param condition boolean Condition to check
---@param message string Error message if assertion fails
function M.assert_false(condition, message)
  if condition then
    error(message or "Expected condition to be false")
  end
end

---Asserts that a table contains a specific value
---@param table table Table to search in
---@param value any Value to search for
---@param message string Error message if assertion fails
function M.assert_contains(table, value, message)
  for _, item in ipairs(table) do
    if item == value then
      return
    end
  end
  error(message or string.format("Expected table to contain %s", tostring(value)))
end

---Creates a test context for spec files
---@return table test_context Test context with common setup
function M.create_test_context()
  local temp_dir = M.create_temp_directory()
  return {
    base_dir = temp_dir,
    temp_files = {},
    cleanup = function(self)
      M.cleanup_test_files(self.temp_files)
      if vim.fn.isdirectory(self.base_dir) == 1 then
        vim.fn.delete(self.base_dir, "rf")
      end
    end,
    add_temp_file = function(self, file_path)
      table.insert(self.temp_files, file_path)
    end
  }
end

return M