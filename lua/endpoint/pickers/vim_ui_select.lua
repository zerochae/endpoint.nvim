---@class endpoint.VimUISelectPicker
-- Vim UI Select Picker Implementation (Function-based)
local M = {}

-- Always available (built into Neovim)
function M.is_available()
  return true
end

-- Show endpoints in vim.ui.select
function M.show(endpoints, opts)
  opts = opts or {}

  if #endpoints == 0 then
    vim.notify("No endpoints found", vim.log.levels.INFO)
    return
  end

  vim.ui.select(endpoints, {
    prompt = "Select endpoint:",
    format_item = function(item)
      return item.display_value
    end,
  }, function(choice)
    if choice then
      vim.cmd("edit " .. choice.file_path)
      vim.api.nvim_win_set_cursor(0, { choice.line_number, choice.column - 1 })
      -- Center the line in the window
      vim.cmd("normal! zz")
    end
  end)
end

return M

