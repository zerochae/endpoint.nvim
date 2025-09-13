---@class endpoint.frameworks.react_router
local M = {}

local fs = require "endpoint.utils.fs"

-- Find component file with various resolution strategies
---@param component_name string
---@return string|nil
local function find_component_file(component_name)
  if not component_name then
    return nil
  end

  -- Common file extensions for React components
  local extensions = { ".tsx", ".jsx", ".ts", ".js" }
  -- Common directory patterns for React projects
  local search_dirs = { "src", "app", "components", "pages" }

  -- Strategy 1: Direct file search (e.g., Home.tsx, Home.jsx)
  local function try_direct_file(dir, name)
    for _, ext in ipairs(extensions) do
      local file_path = dir and (dir .. "/" .. name .. ext) or (name .. ext)
      if fs.has_file { file_path } then
        return file_path
      end
    end
    return nil
  end

  -- Strategy 2: Index file search (e.g., Home/index.tsx)
  local function try_index_file(dir, name)
    for _, ext in ipairs(extensions) do
      local file_path = dir and (dir .. "/" .. name .. "/index" .. ext) or (name .. "/index" .. ext)
      if fs.has_file { file_path } then
        return file_path
      end
    end
    return nil
  end

  -- Strategy 3: Recursive search in common directories
  local function try_recursive_search(name)
    for _, search_dir in ipairs(search_dirs) do
      if fs.has_file { search_dir } then
        -- Try direct file in search directory
        local direct = try_direct_file(search_dir, name)
        if direct then
          return direct
        end

        -- Try index file in search directory
        local index = try_index_file(search_dir, name)
        if index then
          return index
        end

        -- Try nested search (e.g., src/components/Home.tsx)
        local nested_dirs = { "components", "pages", "views", "containers" }
        for _, nested in ipairs(nested_dirs) do
          local nested_direct = try_direct_file(search_dir .. "/" .. nested, name)
          if nested_direct then
            return nested_direct
          end

          local nested_index = try_index_file(search_dir .. "/" .. nested, name)
          if nested_index then
            return nested_index
          end
        end
      end
    end
    return nil
  end

  -- Try current directory first
  local current_direct = try_direct_file(nil, component_name)
  if current_direct then
    return current_direct
  end

  local current_index = try_index_file(nil, component_name)
  if current_index then
    return current_index
  end

  -- Try recursive search
  return try_recursive_search(component_name)
end

-- Detection
---@return boolean
function M.detect()
  -- Check for React project files
  local has_package = fs.has_file { "package.json" }
  if not has_package then
    return false
  end

  -- Check for React Router in package.json dependencies
  local has_react_router = fs.file_contains("package.json", "react-router")
  local has_react_router_dom = fs.file_contains("package.json", "react-router-dom")

  if has_react_router or has_react_router_dom then
    return true
  end

  return false
end

-- Search command generation
---@param method string Any HTTP method - all will be treated as ROUTE
---@return string
function M.get_search_cmd(method)
  -- React Router only searches for route definitions
  local patterns = {
    "Route", -- <Route> components
    "path:", -- createBrowserRouter array format
  }

  local cmd = "rg --line-number --column --no-heading --color=never"
  cmd = cmd .. " --glob '**/*.js'"
  cmd = cmd .. " --glob '**/*.jsx'"
  cmd = cmd .. " --glob '**/*.ts'"
  cmd = cmd .. " --glob '**/*.tsx'"
  cmd = cmd .. " --glob '!**/node_modules/**'"
  cmd = cmd .. " --glob '!**/dist/**'"
  cmd = cmd .. " --glob '!**/build/**'"

  -- Add patterns
  for _, pattern in ipairs(patterns) do
    cmd = cmd .. " -e '" .. pattern .. "'"
  end

  return cmd
end

-- Parse ripgrep output line
---@param line string
---@param method string Any HTTP method - ignored, always returns ROUTE
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

  local route_path, component_name

  -- Pattern 1: <Route path="/users" element={<Users />} />
  local path, comp = content:match "<Route[^>]*path=['\"]([^'\"]+)['\"][^>]*element=%{<([^%s/>]+)"
  if path and comp then
    route_path = path
    component_name = comp
  end

  if not route_path then
    -- Pattern 2: { path: "/users", element: <Users /> }
    path, comp = content:match "path:%s*['\"]([^'\"]+)['\"].-element:%s*<([^%s/>]+)"
    if path and comp then
      route_path = path
      component_name = comp
    end
  end

  if not route_path then
    -- Pattern 3: Simple <Route path="/users" /> without element
    route_path = content:match "<Route[^>]*path=['\"]([^'\"]+)['\"]"
  end

  if not route_path then
    return nil
  end

  -- Clean up the path (remove extra whitespace)
  route_path = route_path:gsub("^%s+", ""):gsub("%s+$", "")

  -- Create display value (clean route path only)
  local display_value = "ROUTE " .. route_path

  -- Find component file path if component_name exists
  local component_file_path
  if component_name then
    component_file_path = find_component_file(component_name)
  end

  return {
    method = "ROUTE",
    endpoint_path = route_path,
    file_path = file_path,
    line_number = tonumber(line_number),
    column = tonumber(column),
    display_value = display_value,
    component_name = component_name,
    component_file_path = component_file_path, -- 실제 컴포넌트 파일 경로
  }
end

return M
