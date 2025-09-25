local Picker = require "endpoint.core.Picker"
local Highlighter = require "endpoint.core.Highlighter"
local log = require "endpoint.utils.log"

---@class endpoint.SnacksPicker
local SnacksPicker = Picker:new "snacks"
SnacksPicker.__index = SnacksPicker

---Creates a new SnacksPicker instance
function SnacksPicker:new()
  local snacksPicker = setmetatable({}, SnacksPicker)
  snacksPicker.snacks_available = pcall(require, "snacks")
  snacksPicker.highlighter = Highlighter:new "endpoint_snacks_highlight"
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
  local config_module = require "endpoint.config"
  local config = config_module.get()

  -- Use common theme formatting from base Picker
  local display_text = self:_format_endpoint_with_theme(endpoint, config)

  -- Get theme data for highlighting in the picker list
  local method_icon = self.themes:get_method_icon(endpoint.method, config)
  local method_text = self.themes:get_method_text(endpoint.method, config)
  local method_color = self.themes:get_method_color(endpoint.method, config)

  -- Calculate highlight length for method part
  local highlight_length = self.highlighter:calculate_highlight_length(endpoint, method_icon, method_text)

  local item = {
    text = display_text,
    value = endpoint, -- Store endpoint data in value
    file = endpoint.file_path, -- Required for file preview
    -- Use snacks internal pos format: [row, col] - adjust col to 0-based for extmark
    pos = { endpoint.line_number, endpoint.column - 1 },
  }

  -- Add multiline range highlighting support
  if endpoint.end_line_number and endpoint.end_line_number > endpoint.line_number then
    -- Multiline annotation: highlight from start to end line
    item.end_pos = { endpoint.end_line_number, endpoint.end_column or 0 }
  else
    -- Single line: calculate end column
    local end_col = self:_calculate_end_column(endpoint)
    item.end_pos = { endpoint.line_number, end_col }
  end

  -- Add highlighting for the picker list (method highlighting)
  -- Use snacks.nvim extmark-based highlighting - flat array format
  if method_color and highlight_length > 0 then
    item.highlights = {
      { col = 0, end_col = highlight_length, hl_group = method_color },
    }
  end

  return item
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
  local config_module = require "endpoint.config"
  local config = config_module.get()
  local enable_highlighting = self.highlighter:is_highlighting_enabled(config)

  local default_config = {
    source = "Endpoint ",
    items = items,
    prompt = "Endpoints ",
    format = function(item)
      local ret = {}
      ret[#ret + 1] = { item.text }

      -- Add method highlighting if available
      if item.highlights then
        for _, highlight in ipairs(item.highlights) do
          ret[#ret + 1] = highlight
        end
      end

      return ret
    end,
    preview = enable_highlighting and "file" or false, -- Disable preview if highlighting is disabled
    matcher = {
      fuzzy = true,
      smartcase = true,
      file_pos = true, -- Support patterns like `file:line:col`
    },
  }

  -- If highlighting is disabled but user still wants preview, use simple file preview without highlighting
  if not enable_highlighting and opts and opts.preview then
    default_config.preview = "file"
  end

  -- Merge user picker_opts with defaults (user options override defaults)
  return vim.tbl_deep_extend("force", default_config, opts or {})
end

return SnacksPicker
