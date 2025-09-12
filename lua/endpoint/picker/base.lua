local core_base = require "endpoint.core.base"

-- Required methods that picker implementations must provide
local required_methods = {
  "is_available",
  "create_picker",
}

-- Optional methods with default implementations
local optional_methods = {
  get_default_config = function()
    return {}
  end,
  validate_options = function()
    return true
  end,
}

-- Create base class for pickers
local M = core_base.create_base(required_methods, optional_methods)

return M
