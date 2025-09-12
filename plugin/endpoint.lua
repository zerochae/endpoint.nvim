-- Main Endpoint command with all subcommands consolidated
---@param opts table
vim.api.nvim_create_user_command("Endpoint", function(opts)
  local endpoint = require "endpoint"
  local subcommand = opts.fargs[1]
  if not subcommand then
    -- Default to "All" when no subcommand is provided
    subcommand = "All"
  end

  local method = string.upper(subcommand)
  local config = endpoint.get_config()

  if method == "GET" then
    endpoint.pick_get_mapping(config.get or {})
  elseif method == "POST" then
    endpoint.pick_post_mapping(config.post or {})
  elseif method == "PUT" then
    endpoint.pick_put_mapping(config.put or {})
  elseif method == "DELETE" then
    endpoint.pick_delete_mapping(config.delete or {})
  elseif method == "PATCH" then
    endpoint.pick_patch_mapping(config.patch or {})
  elseif method == "ALL" then
    endpoint.pick_all_endpoints {}
  elseif method == "CLEARCACHE" then
    local cache = require "endpoint.services.cache"
    cache.clear_persistent_cache()
    vim.notify("Endpoint cache cleared", vim.log.levels.INFO)
  elseif method == "CACHESTATUS" then
    local cache = require "endpoint.services.cache"
    cache.show_cache_status()
  else
    vim.notify(
      "Unknown method: " .. subcommand .. ". Available: Get, Post, Put, Delete, Patch, All, ClearCache, CacheStatus",
      vim.log.levels.ERROR
    )
  end
end, {
  nargs = "?", -- Optional argument (0 or 1)
  ---@return string[]
  complete = function()
    return { "Get", "Post", "Put", "Delete", "Patch", "All", "ClearCache", "CacheStatus" }
  end,
})
