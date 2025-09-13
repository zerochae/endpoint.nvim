---@class endpoint.pickers.vim_ui_select
local M = {}

-- Always available (built into Neovim)
---@return boolean
function M.is_available()
  return true
end

-- Show endpoints in vim.ui.select
---@param endpoints endpoint.entry[]
---@param opts? table
function M.show(endpoints, opts)
  opts = opts or {}

  if #endpoints == 0 then
    vim.notify("No endpoints found", vim.log.levels.INFO)
    return
  end

  vim.ui.select(endpoints, {
    prompt = "Select endpoint:",
    format_item = function(item)
      -- Use display_value if available (for Rails action annotations), otherwise use default format
      return item.display_value or (item.method .. " " .. item.endpoint_path)
    end,
  }, function(choice)
    if choice then
      vim.cmd("edit " .. choice.file_path)
      vim.api.nvim_win_set_cursor(0, { choice.line_number, choice.column - 1 })
      -- Center the line in the window
      vim.cmd "normal! zz"
    end
  end)
end

return M
