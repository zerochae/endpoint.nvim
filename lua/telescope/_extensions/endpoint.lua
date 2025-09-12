-- Telescope Extension for Simplified Endpoint.nvim
local endpoint = require "endpoint.init"

local function endpoint_picker(method)
  return function(opts)
    opts = opts or {}
    opts.picker_opts = opts
    endpoint.find_endpoints(method, opts)
  end
end

return require("telescope").register_extension {
  setup = function(_)
    -- Extension-specific setup if needed
  end,
  exports = {
    endpoints = endpoint_picker "ALL",
    get = endpoint_picker "GET",
    post = endpoint_picker "POST",
    put = endpoint_picker "PUT",
    delete = endpoint_picker "DELETE",
    patch = endpoint_picker "PATCH",
  },
}

