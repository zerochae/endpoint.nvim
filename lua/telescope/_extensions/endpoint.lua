-- Telescope Extension for Endpoint.nvim
local endpoint = require "endpoint"

return require("telescope").register_extension {
  exports = function()
    endpoint.find()
  end,
  refresh = function()
    endpoint.refresh()
  end,
}
