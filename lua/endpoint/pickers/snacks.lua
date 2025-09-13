---@class endpoint.pickers.snacks
local M = {}

-- Check if Snacks is available
---@return boolean
function M.is_available()
  return pcall(require, "snacks")
end

-- Show endpoints in Snacks picker
---@param endpoints endpoint.entry[]
---@param opts? table
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

  -- Create items according to snacks documentation
  local items = {}
  for _, endpoint in ipairs(endpoints) do
    local display_text = endpoint.display_value or (endpoint.method .. " " .. endpoint.endpoint_path)

    -- Calculate end_pos by reading the actual line length
    local end_col = endpoint.column - 1 + 10 -- Default to 10 chars
    if endpoint.file_path then
      local file = io.open(endpoint.file_path, "r")
      if file then
        local line_num = 1
        for line in file:lines() do
          if line_num == endpoint.line_number then
            end_col = #line -- Use actual line length
            break
          end
          line_num = line_num + 1
        end
        file:close()
      end
    end

    table.insert(items, {
      text = display_text,
      value = endpoint, -- Store endpoint data in value
      file = endpoint.file_path, -- Required for file preview
      -- Use snacks internal pos format: [row, col] - adjust col to 0-based for extmark
      pos = { endpoint.line_number, endpoint.column - 1 },
      -- Add end_pos with actual line length
      end_pos = { endpoint.line_number, end_col },
    })
  end

  if vim.g.endpoint_debug then
    vim.notify("Snacks picker: " .. #items .. " items prepared", vim.log.levels.INFO)
    if #items > 0 then
      local first_item = items[1]
      vim.notify("First item structure: " .. vim.inspect(first_item), vim.log.levels.INFO)
    end
  end

  -- Use official snacks.picker.pick API with explicit keymaps
  snacks.picker.pick {
    source = "endpoints",
    items = items,
    prompt = "Endpoints ",
    format = "text", -- Keep simple format for now
    preview = "file", -- Back to simple working preview
    matcher = {
      fuzzy = true,
      smartcase = true,
      file_pos = true, -- Support patterns like `file:line:col`
    },
  }
end

return M
