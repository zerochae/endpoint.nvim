local Picker = require "endpoint.core.Picker"
local log = require "endpoint.utils.log"

---@class endpoint.SnacksPicker : endpoint.Picker
local SnacksPicker = setmetatable({}, { __index = Picker })
SnacksPicker.__index = SnacksPicker

---Creates a new SnacksPicker instance
function SnacksPicker:new()
  local snacksPicker = setmetatable({}, self)
  snacksPicker.name = "snacks"
  snacksPicker.snacks_available = pcall(require, "snacks")
  return snacksPicker
end

---Check if Snacks is available
function SnacksPicker:is_available()
  return self.snacks_available
end

---Show endpoints in Snacks picker
function SnacksPicker:show(endpoints, opts)
  if not self:is_available() then
    vim.notify("Snacks is not available", vim.log.levels.ERROR)
    return
  end

  if not self:_validate_endpoints(endpoints) then
    return
  end

  local snacks = require "snacks"
  opts = opts or {}

  local items = self:_create_items(endpoints)

  if vim.g.endpoint_debug then
    self:_debug_log_items(items)
  end

  local config = self:_create_picker_config(items, opts)
  snacks.picker.pick(config)
end

---Create picker items from endpoints
function SnacksPicker:_create_items(endpoints)
  local items = {}
  for _, endpoint in ipairs(endpoints) do
    local item = self:_create_item(endpoint)
    table.insert(items, item)
  end
  return items
end

---Create a single picker item from an endpoint
function SnacksPicker:_create_item(endpoint)
  local display_text = self:_format_endpoint_display(endpoint)
  local end_col = self:_calculate_end_column(endpoint)

  return {
    text = display_text,
    value = endpoint, -- Store endpoint data in value
    file = endpoint.file_path, -- Required for file preview
    -- Use snacks internal pos format: [row, col] - adjust col to 0-based for extmark
    pos = { endpoint.line_number, endpoint.column - 1 },
    -- Add end_pos with actual line length
    end_pos = { endpoint.line_number, end_col },
  }
end

---Calculate end column for highlighting by reading actual file
function SnacksPicker:_calculate_end_column(endpoint)
  local default_end_col = endpoint.column - 1 + 10 -- Default to 10 chars

  if not endpoint.file_path then
    return default_end_col
  end

  local file = io.open(endpoint.file_path, "r")
  if not file then
    return default_end_col
  end

  local line_num = 1
  for line in file:lines() do
    if line_num == endpoint.line_number then
      file:close()
      return #line -- Use actual line length
    end
    line_num = line_num + 1
  end

  file:close()
  return default_end_col
end

---Debug log items for troubleshooting
function SnacksPicker:_debug_log_items(items)
  log.framework_debug("[" .. self.name .. " Picker] Snacks picker: " .. #items .. " items prepared")
  if #items > 0 then
    local first_item = items[1]
    log.framework_debug("[" .. self.name .. " Picker] First item structure: " .. vim.inspect(first_item))
  end
end

---Create picker configuration
function SnacksPicker:_create_picker_config(items, opts)
  local default_config = {
    source = "Endpoint ",
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

  -- Merge user picker_opts with defaults (user options override defaults)
  return vim.tbl_deep_extend("force", default_config, opts or {})
end

-- Create and return singleton instance for backward compatibility
local snacks_picker = SnacksPicker:new()

---@class endpoint.pickers.snacks
local M = {}

---Check if Snacks is available
function M.is_available()
  return snacks_picker:is_available()
end

---Show endpoints in Snacks picker
function M.show(endpoints, opts)
  return snacks_picker:show(endpoints, opts)
end

return M

