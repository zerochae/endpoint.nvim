---@class endpoint.frameworks.react_router
local M = {}

local fs = require "endpoint.utils.fs"

-- Detection
---@return boolean
function M.detect()
  -- Check for React project files
  if not fs.has_file { "package.json" } then
    return false
  end

  -- Check for React Router in package.json dependencies
  if fs.file_contains("package.json", "react-router") or fs.file_contains("package.json", "react-router-dom") then
    return true
  end

  return false
end

-- Search command generation
---@param method string
---@return string
function M.get_search_cmd(method)
  -- For React Router, we treat all routes as "ROUTE" method
  -- since they're client-side routes, not HTTP methods
  local patterns = {
    ROUTE = {
      "<Route\\s+path=", -- <Route path="/users" />
      "path:\\s*['\"]", -- { path: "/users", element: ... }
      "navigate\\s*\\(['\"]", -- navigate('/users')
      "useNavigate.*['\"]", -- const nav = useNavigate(); nav('/users')
      "Link.*to=['\"]", -- <Link to="/users">
      "NavLink.*to=['\"]", -- <NavLink to="/users">
    },
    ALL = {
      "<Route\\s+path=",
      "path:\\s*['\"]",
      "navigate\\s*\\(['\"]",
      "useNavigate.*['\"]",
      "Link.*to=['\"]",
      "NavLink.*to=['\"]",
    },
  }

  -- For React Router, we always use ROUTE patterns regardless of method
  -- since client-side routes are always the same type
  local method_patterns = patterns.ROUTE

  local cmd = "rg --line-number --column --no-heading --color=never"
  cmd = cmd .. " --glob '**/*.js'"
  cmd = cmd .. " --glob '**/*.jsx'"
  cmd = cmd .. " --glob '**/*.ts'"
  cmd = cmd .. " --glob '**/*.tsx'"
  cmd = cmd .. " --glob '!**/node_modules/**'"
  cmd = cmd .. " --glob '!**/dist/**'"
  cmd = cmd .. " --glob '!**/build/**'"

  -- Add patterns
  for _, pattern in ipairs(method_patterns) do
    cmd = cmd .. " -e '" .. pattern .. "'"
  end

  return cmd
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

  local route_path, component_info

  -- Pattern 1: <Route path="/users" element={<Users />} />
  local path, comp = content:match "<Route[^>]*path=['\"]([^'\"]+)['\"][^>]*element=%{<([^>}]+)"
  if path and comp then
    route_path = path
    component_info = "<" .. comp .. " />"
  end

  if not route_path then
    -- Pattern 2: { path: "/users", element: <Users /> }
    path, comp = content:match "path:%s*['\"]([^'\"]+)['\"].-element:%s*<([^>]+)"
    if path and comp then
      route_path = path
      component_info = "<" .. comp .. " />"
    end
  end

  if not route_path then
    -- Pattern 3: Simple <Route path="/users" /> without element
    route_path = content:match "<Route[^>]*path=['\"]([^'\"]+)['\"]"
  end

  if not route_path then
    -- Pattern 4: navigate('/users') or navigate("/users") - no component info
    route_path = content:match "navigate%s*%(['\"]([^'\"]+)['\"]"
  end

  if not route_path then
    -- Pattern 5: <Link to="/users"> or <NavLink to="/users"> - no component info
    route_path = content:match "to=['\"]([^'\"]+)['\"]"
  end

  if not route_path then
    return nil
  end

  -- Clean up the path (remove extra whitespace)
  route_path = route_path:gsub("^%s+", ""):gsub("%s+$", "")

  -- Create display value with component info if available
  local display_value = "ROUTE " .. route_path
  if component_info then
    display_value = display_value .. " " .. component_info
  end

  return {
    method = "ROUTE", -- All React Router routes are client-side routes
    endpoint_path = route_path,
    file_path = file_path,
    line_number = tonumber(line_number),
    column = tonumber(column),
    display_value = display_value, -- Custom display format
  }
end

return M

