-- Gin Framework Utility Functions
---@class endpoint.frameworks.gin.utils
local M = {}

function M.extract_path(content)
  local path = content:match 'r%.%w+%s*%(%s*["\']([^"\']+)["\']'
  if not path then
    path = content:match '%.%w+%s*%(%s*["\']([^"\']+)["\']'
  end
  return path
end

function M.extract_method(content)
  local method = content:match 'r%.(%w+)%s*%('
  if not method then
    method = content:match '%.(%w+)%s*%('
  end
  return method and method:upper() or "GET"
end

return M