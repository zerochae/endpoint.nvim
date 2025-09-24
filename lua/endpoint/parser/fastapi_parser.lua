local Parser = require "endpoint.core.Parser"

---@class endpoint.FastApiParser
local FastApiParser = setmetatable({}, { __index = Parser })
FastApiParser.__index = FastApiParser

-- ========================================
-- PUBLIC METHODS
-- ========================================

---Creates a new FastApiParser instance
function FastApiParser:new()
  local fastapi_parser = Parser:new {
    parser_name = "fastapi_parser",
    framework_name = "fastapi",
    language = "python",
  }
  setmetatable(fastapi_parser, self)
  return fastapi_parser
end

---Extracts base path from FastAPI router file
function FastApiParser:extract_base_path(file_path, line_number)
  -- Get router prefix from current file or infer from path
  local prefix = self:_find_router_prefix(file_path, line_number)
  if prefix and prefix ~= "" then
    return prefix
  end

  -- If no prefix found, try to infer from file path
  return self:_infer_prefix_from_path(file_path)
end

---Extracts endpoint path from FastAPI decorator content
function FastApiParser:extract_endpoint_path(content, file_path, line_number)
  -- Use multiline extraction for better accuracy
  if file_path and line_number then
    local path, end_line = self:_extract_path_multiline(file_path, line_number, content)
    if path then
      -- Store end_line_number for highlighting
      self._last_end_line_number = end_line
      return path
    end
  end

  -- Fallback to single line extraction (clear end_line for single line)
  self._last_end_line_number = nil
  local path = self:_extract_path_single_line(content)
  if path then
    return path
  end

  return nil
end

---Extracts HTTP method from FastAPI decorator content
function FastApiParser:extract_method(content)
  -- Extract from decorator - support any variable name
  local method = content:match "@[^%.]*%.(%w+)%s*%("
  if method then
    return method:upper()
  end

  return "GET" -- Default fallback
end

---Override parse_content to add FastAPI-specific metadata
function FastApiParser:parse_content(content, file_path, line_number, column)
  -- Pre-extract end_line_number before parent call (parent may reset it)
  local _, end_line = self:_extract_path_multiline(file_path, line_number, content)

  -- Call parent implementation
  local endpoint = Parser.parse_content(self, content, file_path, line_number, column)

  if endpoint then
    -- Add FastAPI-specific tags and metadata
    endpoint.tags = { "python", "fastapi", "decorator" }
    endpoint.metadata = self:create_metadata("decorator", {
      decorator_type = self:_extract_decorator_type(content),
      has_multiline = self:_is_multiline_decorator(content),
    }, content)

    -- Add end_line_number for multiline highlighting
    -- Note: Highlighter does (end_line - 1), so we add +1 to include the closing parenthesis
    if end_line then
      endpoint.end_line_number = end_line + 1
    end
  end

  return endpoint
end

---Validates if content contains FastAPI decorators
function FastApiParser:is_content_valid_for_parsing(content)
  if not Parser.is_content_valid_for_parsing(self, content) then
    return false
  end

  -- Check if content contains FastAPI decorator patterns
  return self:_is_fastapi_decorator_content(content)
end

---Gets parsing confidence for FastAPI decorators
function FastApiParser:get_parsing_confidence(content)
  if not self:is_content_valid_for_parsing(content) then
    return 0.0
  end

  local base_confidence = 0.85
  local confidence_boost = 0

  -- Boost for standard @app or @router patterns
  if content:match "@(app|router)%.%w+%s*%(" then
    confidence_boost = confidence_boost + 0.1
  end

  -- Boost for well-formed paths
  local path = self:extract_endpoint_path(content)
  if path and path:match "^/" then
    confidence_boost = confidence_boost + 0.05
  end

  return math.min(base_confidence + confidence_boost, 1.0)
end

-- ========================================
-- PRIVATE METHODS
-- ========================================

---Checks if content looks like FastAPI decorator content
function FastApiParser:_is_fastapi_decorator_content(content)
  -- Check for FastAPI decorator patterns
  return content:match "@[^%.]*%.%w+%s*%("
end

---Extracts path from FastAPI decorators (single line)
function FastApiParser:_extract_path_single_line(content)
  -- @app.get("/path"), @router.post("/path"), etc.
  local path = content:match "@[^%.]*%.%w+%s*%(%s*[\"']([^\"']*)[\"']"
  if path then
    return path
  end

  return nil
end

---Extracts path handling multiline decorators
function FastApiParser:_extract_path_multiline(file_path, start_line, content)
  -- First try single line extraction
  local path = self:_extract_path_single_line(content)
  if path then
    return path, nil  -- Single line, no end_line
  end

  -- If it's a multiline decorator, read the file to find the path and end line
  if self:_is_multiline_decorator(content) then
    local file = io.open(file_path, "r")
    if not file then
      return nil, nil
    end

    local lines = {}
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()

    local found_path = nil
    local decorator_end_line = nil

    -- Look for the path in the next few lines and find decorator end
    for i = start_line + 1, math.min(start_line + 15, #lines) do
      local line = lines[i]
      if line then
        -- Look for path string in quotes (first occurrence)
        if not found_path then
          local path_match = line:match "%s*[\"']([^\"']*)[\"']"
          if path_match then
            found_path = path_match
          end
        end

        -- Look for decorator closing parenthesis
        if line:match "%s*%)%s*$" then
          decorator_end_line = i
          break
        end

        -- If we hit the function definition, stop
        if line:match "def%s+%w+" or line:match "async%s+def%s+%w+" then
          -- If we found a path but no explicit closing, use the line before function
          if found_path and not decorator_end_line then
            decorator_end_line = i - 1
          end
          break
        end
      end
    end

    -- Return path and end line if found
    if found_path then
      return found_path, decorator_end_line
    end
  end

  return nil, nil
end

---Checks if decorator spans multiple lines
function FastApiParser:_is_multiline_decorator(content)
  return content:match "@[^%.]*%.%w+%s*%(%s*$"
end

---Extracts the decorator type from content
function FastApiParser:_extract_decorator_type(content)
  local app_type, method = content:match "@([^%.]*)(%.%w+)"
  if app_type and method then
    return app_type .. method
  end
  return "unknown"
end

---Finds router prefix in current file
function FastApiParser:_find_router_prefix(file_path, line_number)
  local file = io.open(file_path, "r")
  if not file then
    return ""
  end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  -- Find the main function that returns APIRouter
  local function_start = nil
  local start_line = math.min(line_number, #lines)
  for i = start_line, 1, -1 do
    if lines[i] and lines[i]:match "def%s+%w+.*APIRouter" then
      function_start = i
      break
    end
  end

  if not function_start then
    return ""
  end

  -- Look for APIRouter creation within this function
  for i = function_start, math.min(function_start + 20, #lines) do
    local line = lines[i]
    if line then
      -- Check for APIRouter constructor
      if line:match "router%s*=%s*APIRouter%s*%(" then
        -- Look for prefix in the next few lines
        for j = i, math.min(i + 10, #lines) do
          local router_line = lines[j]
          if router_line then
            -- Look for prefix parameter
            local prefix = router_line:match "prefix%s*=%s*[\"']([^\"']*)[\"']"
            if prefix then
              return prefix
            end

            -- If we hit closing parenthesis, stop
            if router_line:match "%s*%)%s*$" then
              break
            end
          end
        end
      end

      -- Stop if we hit another function definition
      if i > function_start and line:match "def%s+%w+" then
        break
      end
    end
  end

  return ""
end

---Infers prefix from file path
function FastApiParser:_infer_prefix_from_path(file_path)
  -- Look for common FastAPI directory patterns
  -- e.g., /controllers/users/create_user.py -> /users
  -- e.g., /routers/api/v1/users.py -> /api/v1

  local path_parts = {}
  for part in file_path:gmatch "[^/]+" do
    table.insert(path_parts, part)
  end

  -- Find controllers, routers, or similar directory (but not 'fastapi' itself)
  local start_index = nil
  for i, part in ipairs(path_parts) do
    if (part:match "controller" or part:match "router") and part ~= "fastapi" then
      start_index = i + 1
      break
    end
  end

  if start_index and path_parts[start_index] then
    -- Skip common non-route directories
    local route_part = path_parts[start_index]
    if route_part ~= "http" and route_part ~= "presentation" and not route_part:match "%.py$" then
      return "/" .. route_part
    end

    -- Try next part if current is generic
    if start_index + 1 <= #path_parts then
      local next_part = path_parts[start_index + 1]
      if next_part and not next_part:match "%.py$" then
        return "/" .. next_part
      end
    end
  end

  return ""
end

---Combines base path with endpoint path
function FastApiParser:_combine_paths(base, endpoint)
  if not base or base == "" then
    return endpoint
  end
  if not endpoint or endpoint == "" then
    return base
  end

  -- Remove trailing slash from base and leading slash from endpoint
  base = base:gsub("/$", "")
  endpoint = endpoint:gsub("^/", "")

  -- Handle root endpoint case
  if endpoint == "" then
    return base
  end

  return base .. "/" .. endpoint
end

return FastApiParser
