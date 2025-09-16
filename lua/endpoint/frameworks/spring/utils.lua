-- Spring Framework Utility Functions
---@class endpoint.frameworks.spring.utils
local M = {}

-- Extract path from Spring annotations
---@param content string The content line to extract path from
---@return string? path The extracted path or nil
function M.extract_path(content)
  local is_request_mapping = content:match "@RequestMapping"
  local has_method_param = content:match "@RequestMapping.*method%s*="

  -- Skip @RequestMapping unless it has method parameter
  if is_request_mapping and not has_method_param then
    return nil
  end

  -- Path extraction patterns
  local patterns = {
    -- Direct path: @GetMapping("/path")
    "@%w+Mapping%s*%(%s*[\"']([^\"']+)[\"']",
    -- Value parameter: @GetMapping(value = "/path")
    "@%w+Mapping%s*%(%s*value%s*=%s*[\"']([^\"']+)[\"']",
    -- Path parameter: @GetMapping(path = "/path")
    "@%w+Mapping%s*%(%s*path%s*=%s*[\"']([^\"']+)[\"']"
  }

  -- Try patterns for non-RequestMapping annotations
  if not is_request_mapping then
    for _, pattern in ipairs(patterns) do
      local path = content:match(pattern)
      if path then return path end
    end
  end

  -- Handle @RequestMapping with method parameter
  if has_method_param then
    local request_patterns = {
      "@RequestMapping%s*%([^%)]*value%s*=%s*[\"']([^\"']+)[\"']",
      "@RequestMapping%s*%([^%)]*path%s*=%s*[\"']([^\"']+)[\"']",
      "@RequestMapping%s*%(%s*[\"']([^\"']+)[\"']"
    }

    for _, pattern in ipairs(request_patterns) do
      local path = content:match(pattern)
      if path then return path end
    end
  end

  -- No parentheses mapping - root path
  if content:match "@%w+Mapping%s*$" and not content:match "@RequestMapping%s*$" then
    return "/"
  end

  return nil
end

-- Extract HTTP method from annotation
---@param content string The content line to extract method from
---@return string method The HTTP method (GET, POST, etc.)
function M.extract_method(content)
  -- Method mapping table
  local method_map = {
    Get = "GET",
    Post = "POST",
    Put = "PUT",
    Delete = "DELETE",
    Patch = "PATCH"
  }

  -- Extract from annotation type
  local annotation = content:match "@(%w+)Mapping"
  if annotation and method_map[annotation] then
    return method_map[annotation]
  end

  -- Extract from @RequestMapping method parameter
  local method = content:match "@RequestMapping.-method%s*=%s*[^%.]*%.(%w+)"
  if method then
    return method:upper()
  end

  -- Default for @RequestMapping without method
  return "GET"
end

-- Get base path from class-level @RequestMapping
---@param file_path string The file path to read
---@param line_number number The current line number
---@return string base_path The base path from class-level annotation
function M.get_base_path(file_path, line_number)
  local file = io.open(file_path, "r")
  if not file then return "" end

  local lines = {}
  local current_line = 1
  for line in file:lines() do
    table.insert(lines, line)
    if current_line >= line_number then break end
    current_line = current_line + 1
  end
  file:close()

  -- Base path extraction patterns
  local base_patterns = {
    "@RequestMapping%s*%(%s*[\"']([^\"']+)[\"']",
    "@RequestMapping%s*%([^%)]*value%s*=%s*[\"']([^\"']+)[\"']",
    "@RequestMapping%s*%([^%)]*path%s*=%s*[\"']([^\"']+)[\"']"
  }

  -- Look backwards for class-level @RequestMapping
  for i = math.min(line_number, #lines), 1, -1 do
    local line = lines[i]

    -- Check if this is a class declaration
    if line:match "class%s+%w+" then
      -- Look for @RequestMapping on this class or preceding lines
      for j = math.max(1, i - 5), i do
        local annotation_line = lines[j]
        for _, pattern in ipairs(base_patterns) do
          local base_path = annotation_line:match(pattern)
          if base_path then return base_path end
        end
      end
      break
    end
  end

  return ""
end

-- Combine base path with endpoint path
---@param base string? The base path from class-level annotation
---@param endpoint string? The endpoint path from method-level annotation
---@return string combined_path The combined path
function M.combine_paths(base, endpoint)
  if not base or base == "" then
    return endpoint or "/"
  end
  if not endpoint or endpoint == "" or endpoint == "/" then
    return base:gsub("/$", "")
  end

  -- Remove trailing slash from base and leading slash from endpoint
  base = base:gsub("/$", "")
  endpoint = endpoint:gsub("^/", "")

  local combined = base .. "/" .. endpoint
  -- Remove trailing slash unless it's the root path
  if combined ~= "/" then
    combined = combined:gsub("/$", "")
  end

  return combined
end

return M