-- Finder scanner - Responsible for endpoint discovery and list generation
local base = require "endpoint.scanner.base"
local cache = require "endpoint.services.cache"

-- Create scanner registry implementation that inherits from base
local implementation = {}
---@class ScannerRegistryFinder : endpoint.ScannerRegistry
local M = base.new(implementation, "finder")

-- Process method for finding endpoints
function M:process(method, options)
  options = options or {}
  local state = require "endpoint.core.state"
  local config = state.get_config()

  -- Clear cache for real-time mode
  cache.clear_for_realtime_mode()

  -- Skip if cache is valid and not forcing refresh
  if not options.force_refresh and cache.should_use_cache(method, config) then
    return self:get_cached_list(method)
  end

  -- Discover and cache endpoints
  local endpoints = self:discover_endpoints(method)
  if #endpoints > 0 then
    self:save_to_cache(method, endpoints)
  end

  -- Return list format if requested
  if options.format == "list" then
    return self:get_cached_list(method)
  end

  return endpoints
end

-- Get endpoints as array (for pickers)
function M:get_cached_list(method)
  local finder_table = cache.get_find_table()
  local results = {}

  for file_path, mapping_object in pairs(finder_table) do
    if mapping_object[method] then
      local mappings = mapping_object[method]
      if type(mappings) == "table" then
        for _, item in ipairs(mappings) do
          table.insert(results, {
            value = method .. " " .. (item.value or ""),
            method = method,
            path = item.value or "",
            file_path = file_path,
            line_number = item.line_number,
            column = item.column,
          })
        end
      end
    end
  end

  return results
end

-- Scan method (maintains backward compatibility)
function M:scan(method)
  return self:process(method)
end

-- Get list method (maintains backward compatibility)
function M:get_list(method)
  return self:process(method, { format = "list" })
end

return M
