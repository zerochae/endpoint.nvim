local base = require "endpoint.detector.base"

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

-- Create implementation object with all required methods
local implementation = {}

function implementation:can_detect(picker_name)
  return picker_name ~= nil and type(picker_name) == "string"
end

function implementation:detect(picker_name)
  local detector = picker_detectors[picker_name]
  if not detector then
    return false
  end

  local ok, result = pcall(detector)
  return ok and result
end

-- Get all available pickers
function implementation:get_available()
  local available = {}

  for picker_name, _ in pairs(picker_detectors) do
    if self:detect(picker_name) then
      table.insert(available, picker_name)
    end
  end

  return available
end

-- Resolve picker with fallback logic
function implementation:resolve_picker(requested_picker)
  -- If requested picker is available, use it
  if self:detect(requested_picker) then
    return requested_picker
  end

  -- Fallback to vim_ui_select (always available)
  return "vim_ui_select"
end

-- Get picker detection information
function implementation:get_picker_info()
  local info = {}

  for picker_name, _ in pairs(picker_detectors) do
    info[picker_name] = {
      available = self:detect(picker_name),
    }
  end

  return info
end

-- Validate picker name
function implementation:is_valid_picker_name(picker_name)
  return picker_detectors[picker_name] ~= nil
end

-- Get supported picker names
function implementation:get_supported_pickers()
  local supported = {}
  for picker_name, _ in pairs(picker_detectors) do
    table.insert(supported, picker_name)
  end
  table.sort(supported)
  return supported
end

function implementation:get_priority()
  return 80
end

function implementation:get_description()
  return "Picker detector"
end

-- Create the detector implementation instance
---@class DetectorRegistryPicker : endpoint.DetectorRegistry
local M = base.new(implementation, "picker")
return M
