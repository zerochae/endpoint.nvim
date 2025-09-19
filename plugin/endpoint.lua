-- Prevent loading file twice
if vim.g.loaded_endpoint_nvim == 1 then
  return
end
vim.g.loaded_endpoint_nvim = 1

-- Create user commands for old_backup structure

-- Main endpoint finding command
vim.api.nvim_create_user_command("Endpoint", function()
  require("endpoint").find()
end, {
  desc = "Find all endpoints"
})

vim.api.nvim_create_user_command("EndpointRefresh", function()
  require("endpoint").refresh()
end, {
  desc = "Force refresh endpoints (bypass cache)"
})
