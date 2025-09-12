-- FastAPI Framework Implementation (Function-based)
local M = {}

-- Detection
function M.detect()
  -- Check for FastAPI-related files
  if vim.fn.filereadable "requirements.txt" == 1 then
    local content = vim.fn.readfile "requirements.txt"
    for _, line in ipairs(content) do
      if line:match "fastapi" then
        return true
      end
    end
  end

  if vim.fn.filereadable "pyproject.toml" == 1 then
    local content = vim.fn.readfile "pyproject.toml"
    for _, line in ipairs(content) do
      if line:match "fastapi" then
        return true
      end
    end
  end

  return false
end

-- Search command generation
function M.get_search_cmd(method)
  local patterns = {
    GET = { "@.*\\.get" },
    POST = { "@.*\\.post" },
    PUT = { "@.*\\.put" },
    DELETE = { "@.*\\.delete" },
    PATCH = { "@.*\\.patch" },
    ALL = { "@.*\\.(get|post|put|delete|patch)" },
  }

  local method_patterns = patterns[method:upper()] or patterns.ALL

  local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"
  cmd = cmd .. " --glob '**/*.py'"
  cmd = cmd .. " --glob '!**/__pycache__/**'"
  cmd = cmd .. " --glob '!**/venv/**'"

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

  -- Extract endpoint path (handle multiline decorators)
  local endpoint_path = M.extract_path_multiline(file_path, tonumber(line_number), content)
  if not endpoint_path then
    return nil
  end

  -- Try to get base path from router prefix
  local base_path = M.get_base_path(file_path, tonumber(line_number))
  local full_path = M.combine_paths(base_path, endpoint_path)

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
function M.extract_path(content)
  -- @app.get("/path"), @router.post("/path"), etc.
  local path = content:match "@[^%.]*%.%w+%s*%(%s*[\"']([^\"']*)[\"']"
  if path then
    return path
  end

  return nil
end

-- Extract path handling multiline decorators
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
function M.get_base_path(file_path, line_number)
  -- First try to find prefix in current file
  local prefix = M.find_router_prefix(file_path, line_number)
  if prefix and prefix ~= "" then
    return prefix
  end

  -- If no prefix found in current file, try to infer from file path
  return M.infer_prefix_from_path(file_path)
end

-- Find router prefix in current file
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
  for i = line_number, 1, -1 do
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

