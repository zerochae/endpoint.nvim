---@class endpoint.PickerManager
local PickerManager = {}
PickerManager.__index = PickerManager

local config = require "endpoint.config"

---Creates a new PickerManager instance
function PickerManager:new()
  local picker_manager_instance = setmetatable({}, self)
  picker_manager_instance.available_pickers = {}
  picker_manager_instance:_register_default_pickers()
  return picker_manager_instance
end

---Registers default pickers
function PickerManager:_register_default_pickers()
  -- Register built-in pickers
  local TelescopePicker = require "endpoint.pickers.telescope"
  local VimUiSelectPicker = require "endpoint.pickers.vim_ui_select"
  local SnacksPicker = require "endpoint.pickers.snacks"

  self.available_pickers = {
    telescope = TelescopePicker:new(),
    vim_ui_select = VimUiSelectPicker:new(),
    snacks = SnacksPicker:new(),
  }
end

---Gets a picker by name
function PickerManager:get_picker(picker_name)
  return self.available_pickers[picker_name]
end

---Gets all available pickers
function PickerManager:get_all_pickers()
  return vim.deepcopy(self.available_pickers)
end

---Registers a custom picker
function PickerManager:register_picker(picker_name, picker_instance)
  self.available_pickers[picker_name] = picker_instance
end

---Checks if a picker is available
function PickerManager:is_picker_available(picker_name)
  local picker_instance = self.available_pickers[picker_name]
  return picker_instance and picker_instance.is_available and picker_instance:is_available() or false
end

---Gets the best available picker with fallback
---@return endpoint.Picker picker_instance
---@return string picker_name
function PickerManager:get_best_available_picker(preferred_picker_name, fallback_picker_name)
  -- Use user configured picker if no preferred picker is specified
  preferred_picker_name = preferred_picker_name or config.get().picker.type
  fallback_picker_name = fallback_picker_name or "vim_ui_select"

  -- Try preferred picker first
  if self:is_picker_available(preferred_picker_name) then
    return self.available_pickers[preferred_picker_name], preferred_picker_name
  end

  -- Return fallback picker (vim_ui_select as ultimate fallback)
  return self.available_pickers[fallback_picker_name], fallback_picker_name
end

return PickerManager
