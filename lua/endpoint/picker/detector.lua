-- Picker detector
-- Auto-detects available pickers based on installed dependencies

local M = {}

-- Table of pickers with their detection functions
local picker_detectors = {
  telescope = function()
    local ok, _ = pcall(require, "telescope.pickers")
    return ok
  end,
  
  snacks = function()
    local ok, snacks = pcall(require, "snacks")
    return ok and snacks.picker ~= nil
  end,
  
  vim_ui_select = function()
    return vim.ui and vim.ui.select ~= nil
  end,
}

-- Detect if a specific picker is available
-- @param picker_name string: Name of the picker to check
-- @return boolean: true if picker is available
function M.is_picker_available(picker_name)
  local detector = picker_detectors[picker_name]
  if not detector then
    return false
  end
  
  local ok, result = pcall(detector)
  return ok and result
end

-- Get all available pickers
-- @return table: Array of available picker names
function M.get_available_pickers()
  local available = {}
  
  for picker_name, _ in pairs(picker_detectors) do
    if M.is_picker_available(picker_name) then
      table.insert(available, picker_name)
    end
  end
  
  return available
end

-- Resolve picker with fallback logic
-- @param requested_picker string: User requested picker name
-- @return string: Actual picker to use (with fallback to vim_ui_select)
function M.resolve_picker(requested_picker)
  -- If requested picker is available, use it
  if M.is_picker_available(requested_picker) then
    return requested_picker
  end
  
  -- Fallback to vim_ui_select (always available)
  return "vim_ui_select"
end

-- Get picker detection information
-- @return table: Information about each picker's availability
function M.get_picker_info()
  local info = {}
  
  for picker_name, _ in pairs(picker_detectors) do
    info[picker_name] = {
      available = M.is_picker_available(picker_name),
    }
  end
  
  return info
end

-- Validate picker name
-- @param picker_name string: Name to validate
-- @return boolean: true if picker name is supported
function M.is_valid_picker_name(picker_name)
  return picker_detectors[picker_name] ~= nil
end

-- Get supported picker names
-- @return table: Array of supported picker names
function M.get_supported_pickers()
  local supported = {}
  for picker_name, _ in pairs(picker_detectors) do
    table.insert(supported, picker_name)
  end
  table.sort(supported)
  return supported
end

return M