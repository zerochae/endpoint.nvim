local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error "requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)"
end

local endpoint = require "endpoint.core"

return telescope.register_extension {
  setup = function()
    ---@diagnostic disable-next-line: unused-local
    -- telescope extension setup - usually not needed as main setup is handled by plugin/endpoint.lua
  end,
  exports = {
    -- Main endpoint picker (shows all endpoints)
    ---@param opts table?
    endpoint = function(opts)
      return endpoint.pick_all_endpoints(opts) -- Show all endpoints by default
    end,

    -- Individual method pickers
    ---@param opts table?
    get = function(opts)
      return endpoint.pick_get_mapping(opts)
    end,
    ---@param opts table?
    post = function(opts)
      return endpoint.pick_post_mapping(opts)
    end,
    ---@param opts table?
    put = function(opts)
      return endpoint.pick_put_mapping(opts)
    end,
    ---@param opts table?
    delete = function(opts)
      return endpoint.pick_delete_mapping(opts)
    end,
    ---@param opts table?
    patch = function(opts)
      return endpoint.pick_patch_mapping(opts)
    end,
  },
}
