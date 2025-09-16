-- Flask Framework Utility Functions
---@class endpoint.frameworks.flask.utils
local M = {}

-- Extract path from Flask decorators
---@param content string The content line to extract path from
---@return string? path The extracted path or nil
function M.extract_path(content)
  -- @app.route("/path"), @bp.route("/path"), etc.
  local path = content:match '@app%.route%s*%(%s*["\']([^"\']+)["\']'
  if not path then
    path = content:match '@bp%.route%s*%(%s*["\']([^"\']+)["\']'
  end
  if not path then
    path = content:match '@blueprint%.route%s*%(%s*["\']([^"\']+)["\']'
  end
  return path
end

-- Extract HTTP method from Flask route
---@param content string The content line to extract method from
---@return string method The HTTP method (GET, POST, etc.)
function M.extract_method(content)
  -- Look for methods=["GET"] or methods=["POST"]
  local method = content:match 'methods%s*=%s*%[%s*["\'](%w+)["\']'
  return method and method:upper() or "GET" -- Default to GET
end

return M