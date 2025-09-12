-- Snacks Picker Implementation (Function-based)
local M = {}

-- Check if Snacks is available
function M.is_available()
  return pcall(require, "snacks")
end

-- Show endpoints in Snacks picker
function M.show(endpoints, opts)
  if not M.is_available() then
    vim.notify("Snacks is not available", vim.log.levels.ERROR)
    return
  end

  local snacks = require "snacks"
  opts = opts or {}

  if #endpoints == 0 then
    vim.notify("No endpoints found", vim.log.levels.INFO)
    return
  end

  -- Format endpoints for snacks picker
  local items = {}
  for _, endpoint in ipairs(endpoints) do
    table.insert(items, {
      text = endpoint.display_value,
      file = endpoint.file_path,
      line = endpoint.line_number,
      col = endpoint.column,
      endpoint = endpoint,
    })
  end

  snacks.picker.pick {
    source = "static",
    items = items,
    prompt = "Endpoints",
    preview = true,
    finder = function(item)
      return item.text
    end,
    format = function(item)
      return item.text
    end,
    preview_file = function(item)
      return {
        file = item.file,
        line = item.line,
        col = item.col,
      }
    end,
    confirm = function(item)
      if item and item.endpoint then
        vim.cmd("edit " .. item.endpoint.file_path)
        vim.api.nvim_win_set_cursor(0, { item.endpoint.line_number, item.endpoint.column - 1 })
      end
    end,
  }
end

return M

