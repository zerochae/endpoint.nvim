-- Spring Framework Implementation (Function-based)
local M = {}

-- Detection
function M.detect()
  return vim.fn.filereadable "pom.xml" == 1
    or vim.fn.filereadable "build.gradle" == 1
    or vim.fn.filereadable "build.gradle.kts" == 1
    or vim.fn.filereadable "application.properties" == 1
    or vim.fn.filereadable "application.yml" == 1
end

-- Search command generation
function M.get_search_cmd(method)
  local patterns = {
    GET = { "@GetMapping", "@RequestMapping.*method.*=.*GET" },
    POST = { "@PostMapping", "@RequestMapping.*method.*=.*POST" },
    PUT = { "@PutMapping", "@RequestMapping.*method.*=.*PUT" },
    DELETE = { "@DeleteMapping", "@RequestMapping.*method.*=.*DELETE" },
    PATCH = { "@PatchMapping", "@RequestMapping.*method.*=.*PATCH" },
    ALL = {
      "@GetMapping",
      "@PostMapping",
      "@PutMapping",
      "@DeleteMapping",
      "@PatchMapping",
      "@RequestMapping.*method.*=.*GET",
      "@RequestMapping.*method.*=.*POST",
      "@RequestMapping.*method.*=.*PUT",
      "@RequestMapping.*method.*=.*DELETE",
      "@RequestMapping.*method.*=.*PATCH",
      "@RequestMapping",
    },
  }

  local method_patterns = patterns[method:upper()] or patterns.ALL

  local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"
  cmd = cmd .. " --glob '**/*.java'"
  cmd = cmd .. " --glob '!**/target/**'"
  cmd = cmd .. " --glob '!**/build/**'"

  -- Add patterns
  for _, pattern in ipairs(method_patterns) do
    cmd = cmd .. " -e '" .. pattern .. "'"
  end

  return cmd
end

-- Line parsing
function M.parse_line(line, method)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    return nil
  end

  -- Extract endpoint path from various Spring annotations
  local endpoint_path = M.extract_path(content)
  if not endpoint_path then
    return nil
  end

  -- Try to get base path from class-level @RequestMapping
  local base_path = M.get_base_path(file_path, tonumber(line_number))
  local full_path = M.combine_paths(base_path, endpoint_path)

  -- Extract HTTP method from annotation
  local parsed_method = M.extract_method(content, method)

  return {
    file_path = file_path,
    line_number = tonumber(line_number),
    column = tonumber(column),
    method = parsed_method,
    endpoint_path = full_path,
    display_value = parsed_method .. " " .. full_path,
  }
end

-- Extract path from Spring annotations
function M.extract_path(content)
  -- @GetMapping("/path"), @PostMapping(value = "/path"), etc.
  local path = content:match "@%w+Mapping%s*%(%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  -- @GetMapping(value = "/path")
  path = content:match "@%w+Mapping%s*%(%s*value%s*=%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  -- @GetMapping(path = "/path")
  path = content:match "@%w+Mapping%s*%(%s*path%s*=%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  -- @RequestMapping(value = "/path", method = ...)
  path = content:match "@RequestMapping%s*%([^%)]*value%s*=%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  -- @RequestMapping(path = "/path", method = ...)
  path = content:match "@RequestMapping%s*%([^%)]*path%s*=%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  -- @RequestMapping("/path")
  path = content:match "@RequestMapping%s*%(%s*[\"']([^\"']+)[\"']"
  if path then
    return path
  end

  return nil
end

-- Extract HTTP method from annotation
function M.extract_method(content, search_method)
  -- If searching for specific method, return it
  if search_method ~= "ALL" then
    return search_method:upper()
  end

  -- Extract from annotation type
  local annotation = content:match "@(%w+)Mapping"
  if annotation then
    if annotation == "Get" then
      return "GET"
    elseif annotation == "Post" then
      return "POST"
    elseif annotation == "Put" then
      return "PUT"
    elseif annotation == "Delete" then
      return "DELETE"
    elseif annotation == "Patch" then
      return "PATCH"
    end
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
function M.get_base_path(file_path, line_number)
  -- Read file content around the class definition
  local file = io.open(file_path, "r")
  if not file then
    return ""
  end

  local lines = {}
  local current_line = 1
  for line in file:lines() do
    table.insert(lines, line)
    if current_line >= line_number then
      break
    end
    current_line = current_line + 1
  end
  file:close()

  -- Look backwards for class-level @RequestMapping
  for i = math.min(line_number, #lines), 1, -1 do
    local line = lines[i]

    -- Check if this is a class declaration
    if line:match "class%s+%w+" then
      -- Look for @RequestMapping on this class or preceding lines
      for j = math.max(1, i - 5), i do
        local annotation_line = lines[j]
        local base_path = annotation_line:match "@RequestMapping%s*%(%s*[\"']([^\"']+)[\"']"
        if base_path then
          return base_path
        end
        base_path = annotation_line:match "@RequestMapping%s*%([^%)]*value%s*=%s*[\"']([^\"']+)[\"']"
        if base_path then
          return base_path
        end
        base_path = annotation_line:match "@RequestMapping%s*%([^%)]*path%s*=%s*[\"']([^\"']+)[\"']"
        if base_path then
          return base_path
        end
      end
      break
    end
  end

  return ""
end

-- Combine base path with endpoint path
function M.combine_paths(base, endpoint)
  if not base or base == "" then
    return endpoint
  end
  if not endpoint or endpoint == "" then
    return base
  end

  -- Remove trailing slash from base and leading slash from endpoint
  base = base:gsub("/$", "")
  endpoint = endpoint:gsub("^/", "")

  return base .. "/" .. endpoint
end

return M

