local fs = require "endpoint.utils.fs"

---@class endpoint.Detector
local Detector = {}
Detector.__index = Detector

---Creates a new Detector instance with optional fields
function Detector:new(detection_name, fields)
  local detector_instance = setmetatable({}, self)
  detector_instance.detection_name = detection_name or "unknown"

  -- Set additional fields if provided
  if fields then
    for key, value in pairs(fields) do
      detector_instance[key] = value
    end
  end

  -- Initialize file system utils if not provided
  if not detector_instance.file_system_utils then
    detector_instance.file_system_utils = fs
  end

  return detector_instance
end

---Creates a new Detector for dependency-based detection
function Detector:new_dependency_detector(required_dependencies, manifest_files, detection_name)
  local detector = self:new(detection_name or "dependency_based_detection", {
    required_dependencies = required_dependencies or {},
    manifest_files = manifest_files or {},
  })
  return detector
end

---Detects if any of the required dependencies are present in manifest files
function Detector:is_target_detected()
  -- If we have dependencies and manifest files, use dependency detection
  if self.required_dependencies and self.manifest_files then
    for _, manifest_file_path in ipairs(self.manifest_files) do
      if self.file_system_utils.has_file { manifest_file_path } then
        if self:_check_manifest_file_for_dependencies(manifest_file_path) then
          return true
        end
      end
    end
    return false
  end

  -- Default implementation for subclasses
  error("is_target_detected() must be implemented by subclass: " .. self.detection_name)
end

---Checks a specific manifest file for required dependencies
function Detector:_check_manifest_file_for_dependencies(manifest_file_path)
  for _, required_dependency_identifier in ipairs(self.required_dependencies) do
    if self.file_system_utils.file_contains(manifest_file_path, required_dependency_identifier) then
      return true
    end
  end

  return false
end

---Gets the name of this detector
function Detector:get_name()
  return self.detection_name
end

---Gets detailed information about what was detected
function Detector:get_detection_details()
  if not self:is_target_detected() then
    return nil
  end

  local base_details = {
    detector_name = self.detection_name,
    detected_at = os.time(),
    is_detected = true
  }

  -- Add dependency-specific details if applicable
  if self.required_dependencies and self.manifest_files then
    local detected_dependencies = {}
    local searched_manifest_files = {}

    for _, manifest_file_path in ipairs(self.manifest_files) do
      if self.file_system_utils.has_file { manifest_file_path } then
        table.insert(searched_manifest_files, manifest_file_path)

        for _, required_dependency_identifier in ipairs(self.required_dependencies) do
          if self.file_system_utils.file_contains(manifest_file_path, required_dependency_identifier) then
            table.insert(detected_dependencies, {
              dependency_identifier = required_dependency_identifier,
              found_in_manifest = manifest_file_path,
            })
          end
        end
      end
    end

    base_details.detected_dependencies = detected_dependencies
    base_details.searched_manifest_files = searched_manifest_files
    base_details.total_required_dependencies = #self.required_dependencies
    base_details.total_detected_dependencies = #detected_dependencies
  end

  return base_details
end

---Adds additional required dependencies to the detection criteria
function Detector:add_required_dependencies(additional_dependencies)
  if not self.required_dependencies then
    self.required_dependencies = {}
  end
  for _, additional_dependency_identifier in ipairs(additional_dependencies) do
    table.insert(self.required_dependencies, additional_dependency_identifier)
  end
end

---Adds additional manifest files to search in
function Detector:add_manifest_files(additional_manifest_files)
  if not self.manifest_files then
    self.manifest_files = {}
  end
  for _, additional_manifest_file_path in ipairs(additional_manifest_files) do
    table.insert(self.manifest_files, additional_manifest_file_path)
  end
end

---Gets the list of required dependencies
function Detector:get_required_dependencies()
  return vim.deepcopy(self.required_dependencies or {})
end

---Gets the list of manifest files to search
function Detector:get_manifest_files()
  return vim.deepcopy(self.manifest_files or {})
end

return Detector