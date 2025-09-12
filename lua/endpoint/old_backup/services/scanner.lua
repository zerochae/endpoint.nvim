-- Endpoint Scanner - Clean service for discovering API endpoints
-- This is a compatibility wrapper around the new scanner architecture
local scanner_manager = require "endpoint.scanner.manager"

local M = {}

-- Backward compatibility API

-- Scan endpoints for a method
---@param method string
---@return endpoint.Endpoint[]
function M.scan(method)
  return scanner_manager.finder():scan(method)
end

-- Get endpoints as array (for pickers)
---@param method string
---@return endpoint.Endpoint[]
function M.get_list(method)
  return scanner_manager.finder():get_list(method)
end

-- Prepare preview data for UI
---@param method string
---@return table
function M.prepare_preview(method)
  return scanner_manager.previewer():prepare_preview(method)
end

-- Batch scan all HTTP methods efficiently
---@return table<string, endpoint.Endpoint[]>
function M.scan_all()
  return scanner_manager.batch():scan_all_method()
end

-- Cache management
function M.clear_cache()
  return scanner_manager.batch():process(nil, { operation = "clear_cache" })
end

---@return table
function M.get_cache_data()
  return scanner_manager.batch():process(nil, { operation = "get_cache_data" })
end

return M
