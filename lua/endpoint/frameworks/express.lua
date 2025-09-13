---@class endpoint.frameworks.express
local M = {}

local fs = require "endpoint.utils.fs"

-- Detection
---@return boolean
function M.detect()
  -- Quick check for Node.js project files first
  if not fs.has_file { "package.json" } then
    return false
  end

  -- Check for Express in package.json dependencies
  if fs.file_contains("package.json", "express") then
    return true
  end

  return false
end

-- Create search command generator using utility function
local search_utils = require "endpoint.utils.search"
local get_search_cmd = search_utils.create_search_cmd_generator({
  GET = { "app\\.get\\(", "router\\.get\\(", "\\bget\\(" },
  POST = { "app\\.post\\(", "router\\.post\\(", "\\bpost\\(" },
  PUT = { "app\\.put\\(", "router\\.put\\(", "\\bput\\(" },
  DELETE = { "app\\.delete\\(", "router\\.delete\\(", "\\bdel\\(", "\\bdelete\\(" },
  PATCH = { "app\\.patch\\(", "router\\.patch\\(", "\\bpatch\\(" },
  ALL = {
    "app\\.(get|post|put|delete|patch)\\(",
    "router\\.(get|post|put|delete|patch)\\(",
    "\\b(get|post|put|del|delete|patch)\\(",
  },
}, search_utils.common_globs.javascript, search_utils.common_excludes.node)

-- Search command generation
---@param method string
---@return string
function M.get_search_cmd(method)
  return get_search_cmd(method)
end

-- Parse ripgrep output line
---@param line string
---@param method string
---@return table|nil
function M.parse_line(line, method)
  if not line or line == "" then
    return nil
  end

  -- Parse ripgrep output format: file:line:col:content
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path or not line_number or not column or not content then
    return nil
  end

  -- Extract HTTP method and path from Express route definitions
  -- Examples:
  -- app.get('/users', ...)
  -- router.post('/api/users/:id', ...)
  -- get('/users', ...)  (destructured)
  -- post('/api/users', ...)  (destructured)

  local http_method, endpoint_path

  -- Try standard app.method() or router.method() pattern
  local app_type, route_method, path = content:match "(%w+)%.(%w+)%(['\"]([^'\"]+)['\"]"
  if app_type and route_method and path then
    http_method = route_method:upper()
    endpoint_path = path
  else
    -- Try destructured pattern: get('/path', ...) or del('/path', ...)
    local destructured_method, destructured_path = content:match "(%w+)%(['\"]([^'\"]+)['\"]"
    if destructured_method and destructured_path then
      http_method = destructured_method:upper()
      -- Handle 'del' alias for DELETE
      if http_method == "DEL" then
        http_method = "DELETE"
      end
      endpoint_path = destructured_path
    else
      return nil
    end
  end

  -- Validate the method matches what we're searching for
  if method ~= "ALL" and http_method ~= method then
    return nil
  end

  return {
    method = http_method,
    endpoint_path = endpoint_path,
    file_path = file_path,
    line_number = tonumber(line_number),
    column = tonumber(column),
  }
end

return M
