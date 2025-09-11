local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error "requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)"
end

local endpoint = require "endpoint.core"

return telescope.register_extension {
  setup = function()
    -- telescope extension setup - usually not needed as main setup is handled by plugin/endpoint.lua
  end,
  exports = {
    -- Main endpoint picker (shows all endpoints)
    endpoint = function(opts)
      return endpoint.pick_all_endpoints(opts) -- Show all endpoints by default
    end,

    -- Individual method pickers
    get = function(opts)
      return endpoint.pick_get_mapping(opts)
    end,
    post = function(opts)
      return endpoint.pick_post_mapping(opts)
    end,
    put = function(opts)
      return endpoint.pick_put_mapping(opts)
    end,
    delete = function(opts)
      return endpoint.pick_delete_mapping(opts)
    end,
    patch = function(opts)
      return endpoint.pick_patch_mapping(opts)
    end,
  },
}
