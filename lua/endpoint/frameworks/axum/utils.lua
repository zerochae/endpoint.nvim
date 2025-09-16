-- Axum Framework Utility Functions
---@class endpoint.frameworks.axum.utils
local M = {}

-- Extract path from Axum routes
---@param content string The content line to extract path from
---@return string? path The extracted path or nil
function M.extract_path(content)
  -- .route("/path", get(...)), Router::new().route("/path", ...)
  local path = content:match '%.route%s*%(%s*["\']([^"\']+)["\']'
  if not path then
    path = content:match 'route%s*%(%s*["\']([^"\']+)["\']'
  end
  return path
end

-- Extract HTTP method from Axum route
---@param content string The content line to extract method from
---@return string? method The HTTP method or nil
function M.extract_method(content)
  -- Look for get(...), post(...), put(...), delete(...)
  local method = content:match '%.route%s*%([^,]+,%s*(%w+)%s*%('
  if not method then
    method = content:match 'route%s*%([^,]+,%s*(%w+)%s*%('
  end
  return method and method:upper() or "GET"
end

return M