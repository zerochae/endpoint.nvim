local core_base = require "endpoint.core.base"

-- Required methods that detector implementations must provide
local required_methods = {
  "detect",
  "can_detect",
}

-- Optional methods with default implementations
local optional_methods = {
  get_priority = function()
    return 50
  end,
  get_description = function()
    return "Generic detector"
  end,
}

-- Create base class for detector implementations
local M = core_base.create_base(required_methods, optional_methods)

return M
