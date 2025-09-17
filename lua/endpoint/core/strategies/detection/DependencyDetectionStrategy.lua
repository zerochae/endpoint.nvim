local DetectionStrategy = require "endpoint.core.strategies.detection.DetectionStrategy"
local fs = require "endpoint.utils.fs"

---@class DependencyDetectionStrategy : DetectionStrategy
local DependencyDetectionStrategy = setmetatable({}, { __index = DetectionStrategy })
DependencyDetectionStrategy.__index = DependencyDetectionStrategy

---Creates a new DependencyDetectionStrategy instance
---@param required_dependencies string[] List of dependencies that must be present for detection
---@param manifest_files string[] List of manifest files to search in
---@param strategy_name? string Optional name for the strategy
---@return DependencyDetectionStrategy
function DependencyDetectionStrategy:new(required_dependencies, manifest_files, strategy_name)
  local dependency_detection_strategy_instance = DetectionStrategy.new(self, strategy_name or "dependency_based_detection")
  setmetatable(dependency_detection_strategy_instance, self)

  ---@class dependency_detection_strategy_instance : DependencyDetectionStrategy
  dependency_detection_strategy_instance.required_dependencies = required_dependencies or {}
  dependency_detection_strategy_instance.manifest_files = manifest_files or {}
  dependency_detection_strategy_instance.file_system_utils = fs

  return dependency_detection_strategy_instance
end

---Detects if any of the required dependencies are present in manifest files
---@return boolean are_dependencies_found True if any required dependencies are found
function DependencyDetectionStrategy:is_target_detected()
  for _, manifest_file_path in ipairs(self.manifest_files) do
    if self.file_system_utils.has_file { manifest_file_path } then
      if self:_check_manifest_file_for_dependencies(manifest_file_path) then
        return true
      end
    end
  end

  return false
end

---Checks a specific manifest file for required dependencies
---@private
---@param manifest_file_path string Path to the manifest file
---@return boolean contains_required_dependencies True if any required dependencies are found
function DependencyDetectionStrategy:_check_manifest_file_for_dependencies(manifest_file_path)
  for _, required_dependency_identifier in ipairs(self.required_dependencies) do
    if self.file_system_utils.file_contains(manifest_file_path, required_dependency_identifier) then
      return true
    end
  end

  return false
end

---Gets detailed information about which dependencies were detected
---@return table|nil dependency_detection_details Information about detected dependencies or nil if none found
function DependencyDetectionStrategy:get_detection_details()
  local base_detection_details = DetectionStrategy.get_detection_details(self)
  if not base_detection_details then
    return nil
  end

  local detected_dependencies = {}
  local searched_manifest_files = {}

  for _, manifest_file_path in ipairs(self.manifest_files) do
    if self.file_system_utils.has_file { manifest_file_path } then
      table.insert(searched_manifest_files, manifest_file_path)

      for _, required_dependency_identifier in ipairs(self.required_dependencies) do
        if self.file_system_utils.file_contains(manifest_file_path, required_dependency_identifier) then
          table.insert(detected_dependencies, {
            dependency_identifier = required_dependency_identifier,
            found_in_manifest = manifest_file_path
          })
        end
      end
    end
  end

  base_detection_details.detected_dependencies = detected_dependencies
  base_detection_details.searched_manifest_files = searched_manifest_files
  base_detection_details.total_required_dependencies = #self.required_dependencies
  base_detection_details.total_detected_dependencies = #detected_dependencies

  return base_detection_details
end

---Adds additional required dependencies to the detection criteria
---@param additional_dependencies string[] Additional dependencies to check for
function DependencyDetectionStrategy:add_required_dependencies(additional_dependencies)
  for _, additional_dependency_identifier in ipairs(additional_dependencies) do
    table.insert(self.required_dependencies, additional_dependency_identifier)
  end
end

---Adds additional manifest files to search in
---@param additional_manifest_files string[] Additional manifest files to search
function DependencyDetectionStrategy:add_manifest_files(additional_manifest_files)
  for _, additional_manifest_file_path in ipairs(additional_manifest_files) do
    table.insert(self.manifest_files, additional_manifest_file_path)
  end
end

---Gets the list of required dependencies
---@return string[] required_dependencies List of required dependencies
function DependencyDetectionStrategy:get_required_dependencies()
  return vim.deepcopy(self.required_dependencies)
end

---Gets the list of manifest files to search
---@return string[] manifest_files List of manifest files
function DependencyDetectionStrategy:get_manifest_files()
  return vim.deepcopy(self.manifest_files)
end

return DependencyDetectionStrategy