local Picker = require "endpoint.core.Picker"

---@class endpoint.VimUiSelectPicker : endpoint.Picker
local VimUiSelectPicker = setmetatable({}, { __index = Picker })
VimUiSelectPicker.__index = VimUiSelectPicker

---Creates a new VimUiSelectPicker instance
function VimUiSelectPicker:new()
  local vim_ui_select_picker = setmetatable({}, self)
  vim_ui_select_picker.name = "vim_ui_select"
  return vim_ui_select_picker
end

---Check if vim.ui.select is available (always true - built into Neovim)
function VimUiSelectPicker:is_available()
  return true
end

---Show endpoints in vim.ui.select
function VimUiSelectPicker:show(endpoints, opts)
  if not self:_validate_endpoints(endpoints) then
    return
  end

  opts = opts or {}
  local config = self:_create_select_config(opts)

  vim.ui.select(endpoints, config, function(choice)
    if choice then
      self:_navigate_to_endpoint(choice)
    end
  end)
end

---Create vim.ui.select configuration
function VimUiSelectPicker:_create_select_config(opts)
  local default_config = {
    prompt = "Endpoint: ",
    format_item = function(item)
      return self:_format_endpoint_display(item)
    end,
  }

  -- Merge user opts with defaults (user options override defaults)
  return vim.tbl_deep_extend("force", default_config, opts)
end

-- Create and return singleton instance for backward compatibility
local vim_ui_select_picker = VimUiSelectPicker:new()

---@class endpoint.pickers.vim_ui_select
local M = {}

---Check if vim.ui.select is available (always true - built into Neovim)
function M.is_available()
  return vim_ui_select_picker:is_available()
end

---Show endpoints in vim.ui.select
function M.show(endpoints, opts)
  return vim_ui_select_picker:show(endpoints, opts)
end

return M

