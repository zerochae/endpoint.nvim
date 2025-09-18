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
  -- Try various Ktor patterns
  local path = self:_extract_path_from_content(content)
  if path then
    return path
  end

  return nil
end

---Extracts HTTP method from Ktor routing content
function KtorParser:extract_method(content)
  local method = self:_extract_method_from_content(content)
  if method then
    return method:upper()
  end

  return "GET" -- Default fallback
end

---Parses Ktor line and returns array of endpoints
function KtorParser:parse_line_to_endpoints(content, file_path, line_number, column)
  -- Only process if this looks like Ktor routing
  if not self:is_content_valid_for_parsing(content) then
    return {}
  end

  -- Extract method and path
  local http_method, endpoint_path = self:_extract_route_info(content, file_path, line_number)
  if not http_method then
    return {}
  end

  -- Create single endpoint
  local endpoint = {
    method = http_method:upper(),
    endpoint_path = endpoint_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = http_method:upper() .. " " .. endpoint_path,
    confidence = self:get_parsing_confidence(content),
    tags = { "kotlin", "ktor", "routing" },
    metadata = self:create_metadata("routing", {
      routing_type = self:_detect_routing_type(content),
      has_parameters = self:_has_route_parameters(endpoint_path),
    }, content),
  }

  return { endpoint }
end

---Validates if content contains Ktor routing
function KtorParser:is_content_valid_for_parsing(content)
  if not Parser.is_content_valid_for_parsing(self, content) then
    return false
  end

  -- Check if content contains Ktor routing patterns
  return self:_is_ktor_routing_content(content)
end

---Gets parsing confidence for Ktor routing
function KtorParser:get_parsing_confidence(content)
  if not self:is_content_valid_for_parsing(content) then
    return 0.0
  end

  local base_confidence = 0.85
  local confidence_boost = 0

  -- Boost for standard HTTP method patterns
  if content:match "(get|post|put|delete|patch)%(" then
    confidence_boost = confidence_boost + 0.1
  end

  -- Boost for type-safe routing
  if content:match "%w+<[^>]+>%s*{" then
    confidence_boost = confidence_boost + 0.05
  end

  -- Boost for well-formed paths
  local path = self:extract_endpoint_path(content)
  if path and path:match "^/" then
    confidence_boost = confidence_boost + 0.03
  end

  return math.min(base_confidence + confidence_boost, 1.0)
end

-- ========================================
-- PRIVATE METHODS
-- ========================================

---Checks if content looks like Ktor routing content
function KtorParser:_is_ktor_routing_content(content)
  -- Check for Ktor routing patterns
  return content:match "(get|post|put|delete|patch)%("
    or content:match "(get|post|put|delete|patch)<[^>]+>%s*{"
end

---Extracts route information from Ktor patterns
function KtorParser:_extract_route_info(content, file_path, line_number)
  -- Pattern 1: Basic routing - get("/path") { }
  local method, path = content:match '(%w+)%("([^"]+)"'
  if method and path then
    local full_path = self:_get_full_path(path, file_path, line_number)
    return method, full_path
  end

  -- Pattern 2: Basic routing with single quotes - get('/path') { }
  method, path = content:match "(%w+)%('([^']+)'"
  if method and path then
    local full_path = self:_get_full_path(path, file_path, line_number)
    return method, full_path
  end

  -- Pattern 3: Empty path - get() { } within route("prefix") block
  method = content:match "(%w+)%(%)%s*{"
  if method then
    local full_path = self:_get_full_path("", file_path, line_number)
    return method, full_path
  end

  -- Pattern 4: Parameter-only path - get("{id}") { }
  method, path = content:match '(%w+)%("([^"]*)"'
  if method and path and path:match "^{" then
    local full_path = self:_get_full_path(path, file_path, line_number)
    return method, full_path
  end

  -- Pattern 5: Type-safe routing - get<Resource> { }
  method = content:match "(%w+)<[^>]+>%s*{"
  if method then
    return method, "/{resource}"
  end

  return nil, nil
end

---Extracts path from Ktor content
function KtorParser:_extract_path_from_content(content)
  -- Double quotes
  local path = content:match '(%w+)%("([^"]+)"'
  if path then
    return path
  end

  -- Single quotes
  path = content:match "(%w+)%('([^']+)'"
  if path then
    return path
  end

  -- Parameter-only paths
  path = content:match '(%w+)%("([^"]*)"'
  if path and path:match "^{" then
    return path
  end

  return nil
end

---Extracts method from Ktor content
function KtorParser:_extract_method_from_content(content)
  -- Standard patterns
  local method = content:match "(%w+)%(.*{"
  if method and method:match "^(get|post|put|delete|patch)$" then
    return method
  end

  -- Type-safe patterns
  method = content:match "(%w+)<[^>]+>%s*{"
  if method and method:match "^(get|post|put|delete|patch)$" then
    return method
  end

  return nil
end

---Detects the type of Ktor routing
function KtorParser:_detect_routing_type(content)
  if content:match "%w+<[^>]+>%s*{" then
    return "type_safe"
  elseif content:match '%w+%("[^"]*"' then
    return "path_based"
  elseif content:match "%w+%(%)%s*{" then
    return "empty_path"
  else
    return "unknown"
  end
end

---Checks if path has route parameters
function KtorParser:_has_route_parameters(path)
  return path and (path:match "{[^}]+}" ~= nil)
end

---Gets full path by analyzing file context for nested routing
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

---Extracts base paths from nested route() blocks
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

return KtorParser