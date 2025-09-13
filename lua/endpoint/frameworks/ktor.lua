---@class endpoint.frameworks.ktor
local M = {}

local fs = require "endpoint.utils.fs"

-- Detection
---@return boolean
function M.detect()
  -- Check for Kotlin files with Ktor dependencies
  if not fs.is_directory "src" then
    return false
  end

  -- Check for build.gradle or build.gradle.kts with Ktor dependencies
  local has_ktor_deps = fs.file_contains("build.gradle", {
    "ktor-server",
    "io.ktor",
    "io.ktor.plugin",
  }) or fs.file_contains("build.gradle.kts", {
    "ktor-server",
    "io.ktor",
    "io.ktor.plugin",
  })

  -- Check for Kotlin files with Ktor routing
  local has_ktor_code = vim.fn
    .system("find src -name '*.kt' -exec grep -l 'routing\\|get(\\|post(\\|put(\\|delete(' {} \\; 2>/dev/null")
    :match "%S" ~= nil

  return has_ktor_deps or has_ktor_code
end

-- Create search command generator using utility function
local search_utils = require "endpoint.utils.search"
local get_search_cmd = search_utils.create_search_cmd_generator(
  {
    GET = { "get\\(", "get<.*>\\(" },
    POST = { "post\\(", "post<.*>\\(" },
    PUT = { "put\\(", "put<.*>\\(" },
    DELETE = { "delete\\(", "delete<.*>\\(" },
    PATCH = { "patch\\(", "patch<.*>\\(" },
    ALL = {
      "get\\(",
      "post\\(",
      "put\\(",
      "delete\\(",
      "patch\\(",
      "get<.*>\\(",
      "post<.*>\\(",
      "put<.*>\\(",
      "delete<.*>\\(",
      "patch<.*>\\(",
    },
  },
  { "**/*.kt" }, -- Kotlin files only
  { "**/build" }, -- Exclude build directory
  { "--case-sensitive" } -- Kotlin is case-sensitive
)

-- Search command generation
---@param method string
---@return string
function M.get_search_cmd(method)
  return get_search_cmd(method)
end

-- Parse ripgrep output line
---@param line string
---@param method string
---@return endpoint.entry?
function M.parse_line(line, method)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path or not line_number or not column or not content then
    return nil
  end

  -- Extract HTTP method and path from various Ktor patterns
  local http_method, endpoint_path = M.extract_route_info(content, method)
  if not http_method or not endpoint_path then
    return nil
  end

  return {
    method = http_method,
    endpoint_path = endpoint_path,
    file_path = file_path,
    line_number = tonumber(line_number),
    column = tonumber(column),
    display_value = http_method .. " " .. endpoint_path,
  }
end

-- Extract route information from Ktor patterns
---@param content string
---@param search_method string
---@return string?, string?
function M.extract_route_info(content, search_method)
  -- Pattern 1: Basic routing - get("/path") { }
  local method, path = content:match '(%w+)%("([^"]+)"'
  if method and path then
    return method:upper(), path
  end

  -- Pattern 2: Basic routing with single quotes - get('/path') { }
  method, path = content:match "(%w+)%('([^']+)'"
  if method and path then
    return method:upper(), path
  end

  -- Pattern 3: Empty path - get() { } within route("prefix") block
  method = content:match "(%w+)%(%)%s*{"
  if method then
    -- Try to extract base path from surrounding route() context
    local base_path = M.get_route_base_path(content) or "/"
    return method:upper(), base_path
  end

  -- Pattern 4: Parameter-only path - get("{id}") { }
  method, path = content:match '(%w+)%("([^"]*)"'
  if method and path and path:match "^{" then
    local base_path = M.get_route_base_path(content) or ""
    local full_path = base_path == "/" and ("/" .. path) or (base_path .. "/" .. path)
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

-- Extract base path from route() context
---@param content string
---@return string?
function M.get_route_base_path(content)
  -- Look for route("path") pattern in the same line or context
  local route_path = content:match 'route%("([^"]+)"'
  if route_path then
    return route_path
  end

  route_path = content:match "route%('([^']+)'"
  if route_path then
    return route_path
  end

  return nil
end

return M

