-- Ktor Framework Utility Functions
---@class endpoint.frameworks.ktor.utils
local M = {}

-- Extract route information from Ktor patterns
---@param content string
---@param search_method string
---@param file_path string?
---@param line_number number?
---@return string?, string?
function M.extract_route_info(content, search_method, file_path, line_number)
  -- Pattern 1: Basic routing - get("/path") { }
  local method, path = content:match '(%w+)%("([^"]+)"'
  if method and path then
    -- Get full path with context
    local full_path = M.get_full_path(path, file_path, line_number)
    return method:upper(), full_path
  end

  -- Pattern 2: Basic routing with single quotes - get('/path') { }
  method, path = content:match "(%w+)%('([^']+)'"
  if method and path then
    local full_path = M.get_full_path(path, file_path, line_number)
    return method:upper(), full_path
  end

  -- Pattern 3: Empty path - get() { } within route("prefix") block
  method = content:match "(%w+)%(%)%s*{"
  if method then
    local full_path = M.get_full_path("", file_path, line_number)
    return method:upper(), full_path
  end

  -- Pattern 4: Parameter-only path - get("{id}") { }
  method, path = content:match '(%w+)%("([^"]*)"'
  if method and path and path:match "^{" then
    local full_path = M.get_full_path(path, file_path, line_number)
    return method:upper(), full_path
  end

  -- Pattern 5: Type-safe routing - get<Resource> { }
  method = content:match "(%w+)<[^>]+>%s*{"
  if method then
    -- For type-safe routing, we'd need to resolve the resource class
    -- For now, return a generic path
    return method:upper(), "/{resource}"
  end

  -- If no pattern matches and we're searching for a specific method,
  -- assume it's the method we're looking for
  if search_method ~= "ALL" and content:match(search_method:lower() .. "%(") then
    return search_method:upper(), "/"
  end

  return nil, nil
end

-- Extract path (legacy for compatibility)
---@param content string
---@return string?
function M.extract_path(content)
  local _, path = M.extract_route_info(content, "ALL", nil, nil)
  return path
end

-- Extract method (legacy for compatibility)
---@param content string
---@return string?
function M.extract_method(content)
  local method, _ = M.extract_route_info(content, "ALL", nil, nil)
  return method
end

-- Get full path by analyzing file context for nested routing
---@param path string The path segment from the current line
---@param file_path string? Path to the file being analyzed
---@param line_number number? Line number of the current route
---@return string The full constructed path
function M.get_full_path(path, file_path, line_number)
  if not file_path or not line_number then
    return path ~= "" and path or "/"
  end

  local base_paths = M.extract_base_paths_from_file(file_path, line_number)
  local full_path = ""

  -- Build full path from base paths
  for _, base_path in ipairs(base_paths) do
    full_path = full_path .. base_path
  end

  -- Add the current path segment
  if path ~= "" then
    if not path:match "^/" then
      full_path = full_path .. "/" .. path
    else
      full_path = full_path .. path
    end
  end

  -- Ensure path starts with /
  if full_path == "" then
    full_path = "/"
  elseif not full_path:match "^/" then
    full_path = "/" .. full_path
  end

  return full_path
end

-- Extract base paths from nested route() blocks
---@param file_path string
---@param target_line number
---@return string[] Array of base path segments
function M.extract_base_paths_from_file(file_path, target_line)
  local base_paths = {}

  -- Read file content
  local file = io.open(file_path, "r")
  if not file then
    return base_paths
  end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  -- Track nesting level and extract route paths
  local bracket_depth = 0
  local route_stack = {}

  for i = 1, target_line - 1 do
    local line = lines[i]
    if line then
      -- Count opening and closing brackets to track nesting
      local _, open_count = line:gsub("{", "")
      local _, close_count = line:gsub("}", "")

      -- Check for route("path") declarations
      local route_path = line:match 'route%("([^"]+)"' or line:match "route%('([^']+)'"
      if route_path then
        table.insert(route_stack, { path = route_path, depth = bracket_depth })
      end

      bracket_depth = bracket_depth + open_count - close_count

      -- Remove routes that are no longer in scope
      while #route_stack > 0 and route_stack[#route_stack].depth >= bracket_depth do
        table.remove(route_stack)
      end
    end
  end

  -- Extract paths from current scope
  for _, route_info in ipairs(route_stack) do
    table.insert(base_paths, route_info.path)
  end

  return base_paths
end

return M