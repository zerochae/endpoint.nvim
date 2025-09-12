-- Previewer scanner - Responsible for UI preview data preparation
local base = require "endpoint.scanner.base"
local cache = require "endpoint.services.cache"

-- Create scanner registry implementation that inherits from base
---@class ScannerRegistryPreviewer : endpoint.ScannerRegistry
local M = {}

function M:is_available()
  return true
end

-- Process method for preparing preview data
function M:process(method, options)
  options = options or {}

  -- First ensure endpoints are discovered
  local finder = require "endpoint.scanner.registry.finder"
  finder:scan(method)

  local finder_table = cache.get_find_table()

  if method == "ALL" then
    self:prepare_all_previews(finder_table)
  else
    self:prepare_method_previews(finder_table, method)
  end

  return true
end

-- Prepare preview data for all methods
function M:prepare_all_previews(finder_table)
  for path, mapping_object in pairs(finder_table) do
    for annotation, mappings in pairs(mapping_object) do
      if type(mappings) == "table" then
        for _, item in ipairs(mappings) do
          local endpoint = annotation .. " " .. (item.value or "")
          cache.create_preview_entry(endpoint, path, item.line_number, item.column)
        end
      end
    end
  end
end

-- Prepare preview data for specific method
function M:prepare_method_previews(finder_table, method)
  for path, mapping_object in pairs(finder_table) do
    if mapping_object[method] then
      local mappings = mapping_object[method]
      if type(mappings) == "table" then
        for _, item in ipairs(mappings) do
          local endpoint = method .. " " .. (item.value or "")
          cache.create_preview_entry(endpoint, path, item.line_number, item.column)
        end
      end
    end
  end
end

-- Prepare preview method (maintains backward compatibility)
function M:prepare_preview(method)
  return self:process(method)
end

return base.new(M, "previewer")
