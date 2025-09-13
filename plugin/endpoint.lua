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

  if method == "GET" then
    endpoint.find_get()
  elseif method == "POST" then
    endpoint.find_post()
  elseif method == "PUT" then
    endpoint.find_put()
  elseif method == "DELETE" then
    endpoint.find_delete()
  elseif method == "PATCH" then
    endpoint.find_patch()
  elseif method == "ROUTE" then
    endpoint.find_route()
  elseif method == "ALL" then
    endpoint.find_all()
  elseif method == "CLEARCACHE" then
    endpoint.clear_cache()
  elseif method == "CACHESTATUS" then
    endpoint.show_cache_stats()
  else
    vim.notify(
      "Unknown method: " .. subcommand .. ". Available: Get, Post, Put, Delete, Patch, Route, All, ClearCache, CacheStatus",
      vim.log.levels.ERROR
    )
  end
end, {
  nargs = "?", -- Optional argument (0 or 1)
  ---@return string[]
  complete = function()
    return { "Get", "Post", "Put", "Delete", "Patch", "Route", "All", "ClearCache", "CacheStatus" }
  end,
})
