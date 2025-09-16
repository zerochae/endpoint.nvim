-- Express.js Framework Utility Functions
---@class endpoint.frameworks.express.utils
local M = {}

-- Extract path from Express routes
---@param content string The content line to extract path from
---@return string? path The extracted path or nil
function M.extract_path(content)
  local endpoint_path

  -- Try standard app.method() or router.method() pattern
  local app_type, route_method, path = content:match "(%w+)%.(%w+)%(['\"]([^'\"]+)['\"]"
  if app_type and route_method and path then
    endpoint_path = path
  else
    -- Try destructured pattern: get('/path', ...) or del('/path', ...)
    local destructured_method, destructured_path = content:match "(%w+)%(['\"]([^'\"]+)['\"]"
    if destructured_method and destructured_path then
      endpoint_path = destructured_path
    end
  end

  return endpoint_path
end

-- Extract HTTP method from route
---@param content string The content line to extract method from
---@return string? method The HTTP method or nil
function M.extract_method(content)
  local http_method

  -- Try standard app.method() or router.method() pattern
  local app_type, route_method, path = content:match "(%w+)%.(%w+)%(['\"]([^'\"]+)['\"]"
  if app_type and route_method and path then
    http_method = route_method:upper()
  else
    -- Try destructured pattern: get('/path', ...) or del('/path', ...)
    local destructured_method, destructured_path = content:match "(%w+)%(['\"]([^'\"]+)['\"]"
    if destructured_method and destructured_path then
      http_method = destructured_method:upper()
      -- Handle 'del' alias for DELETE
      if http_method == "DEL" then
        http_method = "DELETE"
      end
    end
  end

  return http_method
end

return M