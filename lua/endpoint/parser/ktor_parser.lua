local Parser = require "endpoint.core.Parser"

---@class endpoint.KtorParser
local KtorParser = setmetatable({}, { __index = Parser })
KtorParser.__index = KtorParser

-- ========================================
-- PUBLIC METHODS
-- ========================================

---Creates a new KtorParser instance
function KtorParser:new()
  local ktor_parser = Parser:new {
    parser_name = "ktor_parser",
    framework_name = "ktor",
    language = "kotlin",
  }
  setmetatable(ktor_parser, self)
  return ktor_parser
end

---Extracts base path from Ktor routing file
function KtorParser:extract_base_path(file_path, line_number)
  return self:_get_full_path("", file_path, line_number)
end

---Extracts endpoint path from Ktor routing content
function KtorParser:extract_endpoint_path(content)
  -- Handle multiline patterns by normalizing whitespace
  local normalized_content = content:gsub("%s+", " "):gsub("[\r\n]+", " ")

  -- Pattern 1: Basic routing - get("/path") { } or multiline equivalent
  local method, path = normalized_content:match '(%w+)%s*%(%s*"([^"]+)"%s*%)'
  if method and path then
    return path
  end

  -- Pattern 2: Basic routing with single quotes - get('/path') { } or multiline equivalent
  method, path = normalized_content:match "(%w+)%s*%(%s*'([^']+)'%s*%)"
  if method and path then
    return path
  end

  -- Pattern 3: Parameter-only path - get("{id}") { } or multiline equivalent
  method, path = normalized_content:match '(%w+)%s*%(%s*"([^"]*)"'
  if method and path and path:match "^{" then
    return path
  end

  -- Pattern 4: HTTP method without parentheses (empty path) - get { } or multiline equivalent
  local method_only = normalized_content:match "^%s*(%w+)%s*{"
  if self:_is_valid_http_method(method_only) then
    return "" -- Empty path, will use route context
  end

  return nil
end

---Extracts HTTP method from Ktor routing content
function KtorParser:extract_method(content)
  -- Handle multiline patterns by normalizing whitespace
  local normalized_content = content:gsub("%s+", " "):gsub("[\r\n]+", " ")

  -- Pattern 1: Basic routing with path - get("/path") { } or multiline equivalent
  local method = normalized_content:match "(%w+)%s*%("
  if self:_is_valid_http_method(method) then
    return method:upper()
  end

  -- Pattern 2: HTTP method without parentheses - get { } or multiline equivalent
  method = normalized_content:match "^%s*(%w+)%s*{"
  if self:_is_valid_http_method(method) then
    return method:upper()
  end

  -- Pattern 3: Type-safe routing - get<Resource> { } or multiline equivalent
  method = normalized_content:match "(%w+)%s*<[^>]+>%s*{"
  if self:_is_valid_http_method(method) then
    return method:upper()
  end

  return "GET" -- Default fallback
end

-- ========================================
-- PRIVATE METHODS
-- ========================================

---Checks if a method string is a valid HTTP method
function KtorParser:_is_valid_http_method(method)
  if not method then
    return false
  end
  local lower_method = method:lower()
  return lower_method == "get"
    or lower_method == "post"
    or lower_method == "put"
    or lower_method == "delete"
    or lower_method == "patch"
end

---Get full path by analyzing file context for nested routing
function KtorParser:_get_full_path(path, file_path, line_number)
  if not file_path or not line_number then
    return path ~= "" and path or "/"
  end

  local base_paths = self:_extract_base_paths_from_file(file_path, line_number)
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

---Extract base paths from nested route() blocks
function KtorParser:_extract_base_paths_from_file(file_path, target_line)
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
      local route_path = line:match 'route%s*%("([^"]+)"%)'
      if not route_path then
        route_path = line:match "route%s*%('([^']+)'%)"
      end
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

---Validates if the content is suitable for Ktor endpoint parsing
function KtorParser:is_content_valid_for_parsing(content_to_validate)
  if not content_to_validate or content_to_validate == "" then
    return false
  end

  -- Handle multiline patterns by normalizing whitespace
  local normalized_content = content_to_validate:gsub("%s+", " "):gsub("[\r\n]+", " ")

  -- Exclude route() calls as they only define path segments, not endpoints
  if normalized_content:match "route%s*%(" then
    return false
  end

  -- Pattern 1: HTTP method with parentheses - get("/path") { } or multiline equivalent
  local method = normalized_content:match "(%w+)%s*%("
  if self:_is_valid_http_method(method) then
    return true
  end

  -- Pattern 2: HTTP method without parentheses - get { } or multiline equivalent
  method = normalized_content:match "^%s*(%w+)%s*{"
  if self:_is_valid_http_method(method) then
    return true
  end

  return false
end

return KtorParser

