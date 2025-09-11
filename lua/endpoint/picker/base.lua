-- Base picker class
-- This module defines the base interface that all pickers must implement

local M = {}
M.__index = M

-- Creates a new picker object that inherits from this base
function M.new(implementation, name)
  implementation.name = name or "unknown"
  setmetatable(implementation, M)
  return implementation
end

-- Get the name of this picker
-- @return string: The picker name
function M:get_name()
  return self.name
end

-- Check if the picker is available (dependencies installed)
-- @return boolean: true if picker is available
-- This method must be implemented by each picker
function M:is_available()
  error(string.format("is_available() must be implemented by %s", self.name))
end

-- Create and show a picker
-- @param opts table: Picker options
--   - prompt_title string: Title for the picker prompt
--   - preview_title string: Title for the preview window
--   - items table: Array of items to display
--   - on_select function: Callback when item is selected
--   - format_item function: Function to format display of each item
--   - preview_item function: Function to generate preview for item
--   - picker_opts table: Additional picker-specific options
-- @return boolean: true if picker was successfully created
-- This method must be implemented by each picker
function M:create_picker(opts)
  error(string.format("create_picker() must be implemented by %s", self.name))
end

-- Get default configuration for this picker
-- @return table: Default configuration
function M:get_default_config()
  return {}
end

-- Validate picker-specific options
-- @param opts table: Options to validate
-- @return boolean: true if options are valid
function M:validate_options(opts)
  return true
end

return M