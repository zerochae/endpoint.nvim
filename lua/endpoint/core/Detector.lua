local fs = require "endpoint.utils.fs"
local class = require "endpoint.lib.middleclass"

---@class endpoint.Detector
local Detector = class "Detector"

function Detector:initialize(required_dependencies, manifest_files, detection_name)
  self.detection_name = detection_name or "dependency_detection"
  self.required_dependencies = required_dependencies or {}
  self.manifest_files = manifest_files or {}
end

function Detector:is_target_detected()
  for _, manifest_file_path in ipairs(self.manifest_files) do
    if fs.has_file { manifest_file_path } then
      if self:_check_manifest_file_for_dependencies(manifest_file_path) then
        return true
      end
    end
  end

  if self:_should_check_submodules() then
    local submodule_manifest_files = self:_find_submodule_manifest_files()
    for _, submodule_manifest_path in ipairs(submodule_manifest_files) do
      if self:_check_manifest_file_for_dependencies(submodule_manifest_path) then
        return true
      end
    end
  end

  return false
end

---Checks a specific manifest file for required dependencies
function Detector:_check_manifest_file_for_dependencies(manifest_file_path)
  for _, required_dependency_identifier in ipairs(self.required_dependencies) do
    if fs.file_contains(manifest_file_path, required_dependency_identifier) then
      return true
    end
  end

  return false
end

---Gets the name of this detector
function Detector:get_name()
  return self.detection_name
end

function Detector:get_detection_details()
  if not self:is_target_detected() then
    return nil
  end

  local detected_dependencies = {}
  local searched_manifest_files = {}

  for _, manifest_file_path in ipairs(self.manifest_files) do
    if fs.has_file { manifest_file_path } then
      table.insert(searched_manifest_files, manifest_file_path)

      for _, required_dependency_identifier in ipairs(self.required_dependencies) do
        if fs.file_contains(manifest_file_path, required_dependency_identifier) then
          table.insert(detected_dependencies, {
            dependency_identifier = required_dependency_identifier,
            found_in_manifest = manifest_file_path,
          })
        end
      end
    end
  end

  return {
    detector_name = self.detection_name,
    detected_at = os.time(),
    is_detected = true,
    detected_dependencies = detected_dependencies,
    searched_manifest_files = searched_manifest_files,
    total_required_dependencies = #self.required_dependencies,
    total_detected_dependencies = #detected_dependencies,
  }
end

function Detector:add_required_dependencies(additional_dependencies)
  for _, additional_dependency_identifier in ipairs(additional_dependencies) do
    table.insert(self.required_dependencies, additional_dependency_identifier)
  end
end

function Detector:add_manifest_files(additional_manifest_files)
  for _, additional_manifest_file_path in ipairs(additional_manifest_files) do
    table.insert(self.manifest_files, additional_manifest_file_path)
  end
end

function Detector:get_required_dependencies()
  return vim.deepcopy(self.required_dependencies)
end

function Detector:get_manifest_files()
  return vim.deepcopy(self.manifest_files)
end

function Detector:_should_check_submodules()
  for _, manifest_file in ipairs(self.manifest_files) do
    if manifest_file == "pom.xml" then
      return fs.has_file { "pom.xml" }
    end
  end
  return false
end

---Finds all submodule manifest files for Maven multi-module projects
function Detector:_find_submodule_manifest_files()
  local submodule_manifest_files = {}

  -- Only proceed if root pom.xml exists
  if not fs.has_file { "pom.xml" } then
    return submodule_manifest_files
  end

  -- Use vim.fn.glob to find all pom.xml files in subdirectories
  -- Pattern: */pom.xml finds pom.xml files one level deep (submodules)
  local glob_pattern = "*/pom.xml"
  local found_files = vim.fn.glob(glob_pattern, false, true)

  if type(found_files) == "table" then
    for _, file_path in ipairs(found_files) do
      table.insert(submodule_manifest_files, file_path)
    end
  elseif type(found_files) == "string" and found_files ~= "" then
    table.insert(submodule_manifest_files, found_files)
  end

  return submodule_manifest_files
end

return Detector
