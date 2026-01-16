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
  -- Check for Maven
  if vim.tbl_contains(self.manifest_files, "pom.xml") and fs.has_file { "pom.xml" } then
    return true
  end

  -- Check for Gradle
  -- Even if settings.gradle is not in manifest_files, its presence indicates a Gradle project
  -- where we should look for build.gradle files in submodules
  local gradle_indicators = {
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
  }

  if fs.has_file(gradle_indicators) then
    -- Only return true if we are actually looking for gradle files in this detector
    if
      vim.tbl_contains(self.manifest_files, "build.gradle")
      or vim.tbl_contains(self.manifest_files, "build.gradle.kts")
    then
      return true
    end
  end

  return false
end

---Finds all submodule manifest files for Maven and Gradle multi-module projects
function Detector:_find_submodule_manifest_files()
  local submodule_manifest_files = {}

  -- Maven submodules
  if vim.tbl_contains(self.manifest_files, "pom.xml") and fs.has_file { "pom.xml" } then
    local pom_files = vim.fn.glob("*/pom.xml", false, true)
    if type(pom_files) == "table" then
      vim.list_extend(submodule_manifest_files, pom_files)
    elseif type(pom_files) == "string" and pom_files ~= "" then
      table.insert(submodule_manifest_files, pom_files)
    end
  end

  -- Gradle Groovy submodules
  if vim.tbl_contains(self.manifest_files, "build.gradle") then
    if fs.has_file { "build.gradle", "settings.gradle" } then
      local gradle_files = vim.fn.glob("*/build.gradle", false, true)
      if type(gradle_files) == "table" then
        vim.list_extend(submodule_manifest_files, gradle_files)
      elseif type(gradle_files) == "string" and gradle_files ~= "" then
        table.insert(submodule_manifest_files, gradle_files)
      end
    end
  end

  -- Gradle Kotlin submodules
  if vim.tbl_contains(self.manifest_files, "build.gradle.kts") then
    if fs.has_file { "build.gradle.kts", "settings.gradle.kts" } then
      local kts_files = vim.fn.glob("*/build.gradle.kts", false, true)
      if type(kts_files) == "table" then
        vim.list_extend(submodule_manifest_files, kts_files)
      elseif type(kts_files) == "string" and kts_files ~= "" then
        table.insert(submodule_manifest_files, kts_files)
      end
    end
  end

  return submodule_manifest_files
end

return Detector
