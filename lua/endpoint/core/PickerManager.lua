---@class PickerManager
local PickerManager = {}
PickerManager.__index = PickerManager

---Creates a new PickerManager instance
---@return PickerManager
function PickerManager:new()
  local picker_manager_instance = setmetatable({}, self)
  picker_manager_instance.available_pickers = {}
  picker_manager_instance:_register_default_pickers()
  return picker_manager_instance
end

---Registers default pickers
---@private
function PickerManager:_register_default_pickers()
  -- Register built-in pickers
  self.available_pickers = {
    telescope = require "endpoint.pickers.telescope",
    vim_ui_select = require "endpoint.pickers.vim_ui_select",
    snacks = require "endpoint.pickers.snacks",
  }
end

---Gets a picker by name
---@param picker_name string The name of the picker to retrieve
---@return table|nil picker_instance The picker instance or nil if not found
function PickerManager:get_picker(picker_name)
  return self.available_pickers[picker_name]
end

---Gets all available pickers
---@return table<string, table> available_pickers All registered pickers
function PickerManager:get_all_pickers()
  return vim.deepcopy(self.available_pickers)
end

---Registers a custom picker
---@param picker_name string The name of the picker
---@param picker_instance table The picker instance
function PickerManager:register_picker(picker_name, picker_instance)
  self.available_pickers[picker_name] = picker_instance
end

---Checks if a picker is available
---@param picker_name string The name of the picker to check
---@return boolean is_picker_available True if picker exists and is available
function PickerManager:is_picker_available(picker_name)
  local picker_instance = self.available_pickers[picker_name]
  return picker_instance and picker_instance.is_available and picker_instance.is_available() or false
end

---Gets the best available picker with fallback
---@param preferred_picker_name string The preferred picker name
---@param fallback_picker_name? string Optional fallback picker (defaults to vim_ui_select)
---@return table picker_instance The best available picker
---@return string picker_name The name of the selected picker
function PickerManager:get_best_available_picker(preferred_picker_name, fallback_picker_name)
  fallback_picker_name = fallback_picker_name or "vim_ui_select"

  -- Try preferred picker first
  if self:is_picker_available(preferred_picker_name) then
    return self.available_pickers[preferred_picker_name], preferred_picker_name
  end

  -- Try fallback picker
  if self:is_picker_available(fallback_picker_name) then
    return self.available_pickers[fallback_picker_name], fallback_picker_name
  end

  -- Return vim_ui_select as ultimate fallback
  return self.available_pickers.vim_ui_select, "vim_ui_select"
end

return PickerManager