-- React Router Framework Parser
local utils = require "endpoint.frameworks.react_router.utils"

---@param content string The matched line content
---@param file_path string The file path
---@param line_number number The line number
---@param column number The column number
---@param framework_opts any Framework options
---@return endpoint.entry|nil entry Single endpoint entry or nil
return function(content, file_path, line_number, column, framework_opts)
  if not content or content == "" then
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
    component_file_path = utils.find_component_file(component_name)
  end

  return {
    method = "ROUTE",
    endpoint_path = route_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = display_value,
    confidence = 0.8,
    tags = { "route", "react", "frontend" },
    framework = framework_opts.name,
    metadata = {
      component_name = component_name,
      component_file_path = component_file_path,
    }
  }
end