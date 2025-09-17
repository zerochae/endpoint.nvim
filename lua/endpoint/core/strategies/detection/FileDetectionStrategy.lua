local DetectionStrategy = require "endpoint.core.strategies.detection.DetectionStrategy"

---@class FileDetectionStrategy : DetectionStrategy
---@field private required_indicator_files string[]
---@field private file_system_utils any
local FileDetectionStrategy = setmetatable({}, { __index = DetectionStrategy })
FileDetectionStrategy.__index = FileDetectionStrategy

---Creates a new FileDetectionStrategy instance
---@param required_indicator_files string[] List of files that must be present for detection
---@param strategy_name? string Optional name for the strategy
---@return FileDetectionStrategy
function FileDetectionStrategy:new(required_indicator_files, strategy_name)
  local file_detection_strategy_instance = DetectionStrategy.new(self, strategy_name or "file_based_detection")
  setmetatable(file_detection_strategy_instance, self)

  file_detection_strategy_instance.required_indicator_files = required_indicator_files or {}
  file_detection_strategy_instance.file_system_utils = require "endpoint.utils.fs"

  return file_detection_strategy_instance
end

---Detects if any of the required indicator files are present
---@return boolean are_indicator_files_found True if any required files are found
function FileDetectionStrategy:is_target_detected()
  for _, indicator_file_path in ipairs(self.required_indicator_files) do
    if self.file_system_utils.has_file { indicator_file_path } then
      return true
    end
  end

  return false
end

---Gets detailed information about which files were detected
---@return table|nil file_detection_details Information about detected files or nil if none found
function FileDetectionStrategy:get_detection_details()
  local base_detection_details = DetectionStrategy.get_detection_details(self)
  if not base_detection_details then
    return nil
  end

  local detected_files = {}
  for _, indicator_file_path in ipairs(self.required_indicator_files) do
    if self.file_system_utils.has_file { indicator_file_path } then
      table.insert(detected_files, indicator_file_path)
    end
  end

  base_detection_details.detected_files = detected_files
  base_detection_details.total_required_files = #self.required_indicator_files
  base_detection_details.total_detected_files = #detected_files

  return base_detection_details
end

---Adds additional required files to the detection criteria
---@param additional_files string[] Additional files to check for
function FileDetectionStrategy:add_required_files(additional_files)
  for _, additional_file_path in ipairs(additional_files) do
    table.insert(self.required_indicator_files, additional_file_path)
  end
end

---Gets the list of required indicator files
---@return string[] required_files List of required indicator files
function FileDetectionStrategy:get_required_files()
  return vim.deepcopy(self.required_indicator_files)
end

return FileDetectionStrategy