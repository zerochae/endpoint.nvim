-- Phoenix Framework Utility Functions
---@class endpoint.frameworks.phoenix.utils
local M = {}

function M.extract_path(content)
  local path = content:match '%w+%s*["\']([^"\']+)["\']'
  return path
end

function M.extract_method(content)
  local method = content:match '(%w+)%s*["\']'
  return method and method:upper() or "GET"
end

return M