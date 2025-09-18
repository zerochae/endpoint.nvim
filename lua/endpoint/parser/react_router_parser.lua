local Parser = require "endpoint.core.Parser"

---@class endpoint.ReactRouterParser
local ReactRouterParser = setmetatable({}, { __index = Parser })
ReactRouterParser.__index = ReactRouterParser

-- ========================================
-- PUBLIC METHODS
-- ========================================

---Creates a new ReactRouterParser instance
function ReactRouterParser:new()
  local react_router_parser = Parser:new {
    parser_name = "react_router_parser",
    framework_name = "react_router",
    language = "javascript",
  }
  setmetatable(react_router_parser, self)
  return react_router_parser
end

---Extracts base path from React Router file
function ReactRouterParser:extract_base_path(file_path, line_number)
  return ""  -- React Router routes are typically absolute
end

---Extracts endpoint path from React Router content
function ReactRouterParser:extract_endpoint_path(content)
  local path = self:_extract_route_path(content)
  if path then
    return path
  end

  return nil
end

---Extracts HTTP method from React Router content (always returns ROUTE)
function ReactRouterParser:extract_method(content)
  return "ROUTE"  -- React Router doesn't use HTTP methods, it's client-side routing
end

---Parses React Router line and returns array of endpoints
function ReactRouterParser:parse_line_to_endpoints(content, file_path, line_number, column)
  -- Only process if this looks like React Router content
  if not self:is_content_valid_for_parsing(content) then
    return {}
  end

  local route_path = self:extract_endpoint_path(content)
  if not route_path then
    return {}
  end

  -- Extract component name
  local component_name = self:_extract_component_name(content)
  local component_file_path = nil
  if component_name then
    component_file_path = self:_find_component_file(component_name)
  end

  -- Create single endpoint
  local endpoint = {
    method = "ROUTE",
    endpoint_path = route_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = "ROUTE " .. route_path,
    confidence = self:get_parsing_confidence(content),
    tags = { "javascript", "react", "frontend", "routing" },
    metadata = self:create_metadata("route", {
      component_name = component_name,
      component_file_path = component_file_path,
      route_type = self:_detect_route_type(content),
    }, content),
    component_name = component_name,
    component_file_path = component_file_path,
  }

  return { endpoint }
end

---Validates if content contains React Router patterns
function ReactRouterParser:is_content_valid_for_parsing(content)
  if not Parser.is_content_valid_for_parsing(self, content) then
    return false
  end

  -- Check if content contains React Router patterns
  return self:_is_react_router_content(content)
end

---Gets parsing confidence for React Router patterns
function ReactRouterParser:get_parsing_confidence(content)
  if not self:is_content_valid_for_parsing(content) then
    return 0.0
  end

  local base_confidence = 0.9
  local confidence_boost = 0

  -- Boost for Route component patterns
  if content:match "<Route[^>]*path=" then
    confidence_boost = confidence_boost + 0.05
  end

  -- Boost for createBrowserRouter patterns
  if content:match "path:%s*['\"]" then
    confidence_boost = confidence_boost + 0.03
  end

  -- Boost for component reference
  if self:_extract_component_name(content) then
    confidence_boost = confidence_boost + 0.02
  end

  return math.min(base_confidence + confidence_boost, 1.0)
end

-- ========================================
-- PRIVATE METHODS
-- ========================================

---Checks if content looks like React Router content
function ReactRouterParser:_is_react_router_content(content)
  -- Check for React Router patterns
  return content:match "<Route[^>]*path="
    or content:match "path:%s*['\"]"
    or (content:match "Route" and content:match "path")
end

---Extracts route path from React Router content
function ReactRouterParser:_extract_route_path(content)
  -- Pattern 1: <Route path="/users" element={<Users />} />
  local path = content:match "<Route[^>]*path=['\"]([^'\"]+)['\"]"
  if path then
    return path
  end

  -- Pattern 2: { path: "/users", element: <Users /> }
  path = content:match "path:%s*['\"]([^'\"]+)['\"]"
  if path then
    return path
  end

  return nil
end

---Extracts component name from React Router content
function ReactRouterParser:_extract_component_name(content)
  -- Pattern 1: element={<Users />}
  local component = content:match "element=%{<([^%s/>]+)"
  if component then
    return component
  end

  -- Pattern 2: element: <Users />
  component = content:match "element:%s*<([^%s/>]+)"
  if component then
    return component
  end

  -- Pattern 3: component={Users}
  component = content:match "component=%{([^%s}]+)"
  if component then
    return component
  end

  return nil
end

---Detects the type of React Router route
function ReactRouterParser:_detect_route_type(content)
  if content:match "<Route[^>]*element=" then
    return "jsx_element"
  elseif content:match "element:%s*<" then
    return "object_element"
  elseif content:match "component=" then
    return "component_prop"
  else
    return "unknown"
  end
end

---Finds component file with various resolution strategies
function ReactRouterParser:_find_component_file(component_name)
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
      local file = io.open(file_path, "r")
      if file then
        file:close()
        return file_path
      end
    end
    return nil
  end

  -- Strategy 2: Index file search (e.g., Home/index.tsx)
  local function try_index_file(dir, name)
    for _, ext in ipairs(extensions) do
      local file_path = dir and (dir .. "/" .. name .. "/index" .. ext) or (name .. "/index" .. ext)
      local file = io.open(file_path, "r")
      if file then
        file:close()
        return file_path
      end
    end
    return nil
  end

  -- Strategy 3: Recursive search in common directories
  local function try_recursive_search(name)
    for _, search_dir in ipairs(search_dirs) do
      local dir_file = io.open(search_dir, "r")
      if dir_file then
        dir_file:close()

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

return ReactRouterParser