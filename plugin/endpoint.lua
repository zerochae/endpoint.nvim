-- Prevent loading file twice
if vim.g.loaded_endpoint_nvim == 1 then
  return
end
vim.g.loaded_endpoint_nvim = 1

-- Create user commands for old_backup structure

-- Main endpoint finding command
vim.api.nvim_create_user_command("Endpoint", function(opts)
  ---@diagnostic disable-next-line: undefined-field
  local method = opts.args and string.upper(opts.args) or nil
  require("endpoint").find { method = method }
end, {
  nargs = "?",
  complete = function()
    return { "Get", "Post", "Put", "Delete", "Patch" }
  end,
  desc = "Find endpoints (optionally filter by method: Get, Post, etc.)",
})

vim.api.nvim_create_user_command("EndpointRefresh", function()
  require("endpoint").refresh()
end, {
  desc = "Force refresh endpoints (bypass cache)",
})
