---@class endpoint.frameworks.fastapi
local M = {}

local fs = require "endpoint.utils.fs"

-- Detection
---@return boolean
function M.detect()
  -- Quick check for Python project files first
  if not fs.has_file { "requirements.txt", "pyproject.toml", "setup.py", "Pipfile" } then
    return false
  end

  -- Check for FastAPI dependencies
  if fs.file_contains("requirements.txt", "fastapi") then
    return true
  end

  if fs.file_contains("pyproject.toml", "fastapi") then
    return true
  end

  return false
end

-- Search command generation
---@param method string
---@return string
function M.get_search_cmd(method)
  -- Create search command generator using utility function
  local search_utils = require "endpoint.utils.search"
  local search_cmd_generator = search_utils.create_search_cmd_generator(
    {
      GET = { "@app.get", "@router.get" },
      POST = { "@app.post", "@router.post" },
      PUT = { "@app.put", "@router.put" },
      DELETE = { "@app.delete", "@router.delete" },
      PATCH = { "@app.patch", "@router.patch" },
      ALL = {
        "@app.get",
        "@app.post",
        "@app.put",
        "@app.delete",
        "@app.patch",
        "@router.get",
        "@router.post",
        "@router.put",
        "@router.delete",
        "@router.patch",
      },
    },
    search_utils.common_globs.python,
    search_utils.common_excludes.python,
    { "--case-sensitive" } -- FastAPI decorators are case-sensitive
  )

  return search_cmd_generator(method)
end

-- Line parsing
---@param line string
---@param method string
---@return endpoint.entry?
function M.parse_line(line, method)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    return nil
  end

  line_number = tonumber(line_number)

  -- Extract endpoint path (handle multiline decorators)
  local endpoint_path = line_number and M.extract_path_multiline(file_path, line_number, content)
  if not endpoint_path then
    return nil
  end

  -- Try to get base path from router prefix
  local base_path = line_number and M.get_base_path(file_path, line_number)
  local full_path = base_path and M.combine_paths(base_path, endpoint_path)

  -- Extract HTTP method
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

-- Extract path from FastAPI decorators (single line)
---@param content string
---@return string?
function M.extract_path(content)
  -- @app.get("/path"), @router.post("/path"), etc.
  local path = content:match "@[^%.]*%.%w+%s*%(%s*[\"']([^\"']*)[\"']"
  if path then
    return path
  end

  return nil
end

-- Extract path handling multiline decorators
---@param file_path string
---@param start_line number
---@param content string
---@return string?
function M.extract_path_multiline(file_path, start_line, content)
  -- First try single line extraction
  local path = M.extract_path(content)
  if path then
    return path
  end

  -- If it's a multiline decorator, read the file to find the path
  if content:match "@[^%.]*%.%w+%s*%(%s*$" then
    local file = io.open(file_path, "r")
    if not file then
      return nil
    end

    local lines = {}
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()

    -- Look for the path in the next few lines
    for i = start_line + 1, math.min(start_line + 5, #lines) do
      local line = lines[i]
      if line then
        -- Look for path string in quotes
        local found_path = line:match "%s*[\"']([^\"']*)[\"']"
        if found_path then
          return found_path
        end

        -- If we hit the function definition, stop
        if line:match "def%s+%w+" then
          break
        end
      end
    end
  end

  return nil
end

-- Extract HTTP method
---@param content string
---@param search_method string
---@return string
function M.extract_method(content, search_method)
  -- If searching for specific method, return it
  if search_method ~= "ALL" then
    return search_method:upper()
  end

  -- Extract from decorator - support any variable name
  local method = content:match "@[^%.]*%.(%w+)%s*%("
  if method then
    return method:upper()
  end

  return "GET"
end

-- Get base path from router prefix
---@param file_path string
---@param line_number number
---@return string
function M.get_base_path(file_path, line_number)
  -- First try to find prefix in current file
  local prefix = M.find_router_prefix(file_path, line_number)
  if prefix and prefix ~= "" then
    return prefix
  end

  -- If no prefix found in current file, try to infer from file path
  return M.infer_prefix_from_path(file_path)
end

-- Get router prefix (alias for find_router_prefix for testing compatibility)
---@param file_path string
---@param line_number? number
---@return string
function M.get_router_prefix(file_path, line_number)
  -- If line_number is not provided, scan the entire file
  if not line_number then
    line_number = math.huge
  end
  return M.find_router_prefix(file_path, line_number)
end

-- Find router prefix in current file
---@param file_path string
---@param line_number number
---@return string
function M.find_router_prefix(file_path, line_number)
  local file = io.open(file_path, "r")
  if not file then
    return ""
  end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  -- Find the main function that returns APIRouter (skip inner async def functions)
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

-- Infer prefix from file path
---@param file_path string
---@return string
function M.infer_prefix_from_path(file_path)
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

-- Combine base path with endpoint path
---@param base string
---@param endpoint string
---@return string
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

  -- Handle root endpoint case
  if endpoint == "" then
    return base
  end

  return base .. "/" .. endpoint
end

return M
