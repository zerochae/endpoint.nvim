---@class endpoint.frameworks.nestjs
local M = {}

local fs = require "endpoint.utils.fs"

-- Detection
---@return boolean
function M.detect()
  -- Quick check for Node.js project files first
  if not fs.has_file { "package.json", "tsconfig.json", "nest-cli.json" } then
    return false
  end

  if fs.file_contains("package.json", "@nestjs") then
    return true
  end

  return false
end

-- Search command generation
---@param method string
---@return string
function M.get_search_cmd(method)
  local patterns = {
    GET = { "@Get", "@HttpCode.-@Get" },
    POST = { "@Post", "@HttpCode.-@Post" },
    PUT = { "@Put", "@HttpCode.-@Put" },
    DELETE = { "@Delete", "@HttpCode.-@Delete" },
    PATCH = { "@Patch", "@HttpCode.-@Patch" },
    ALL = { "@Get", "@Post", "@Put", "@Delete", "@Patch" },
  }

  local method_patterns = patterns[method:upper()] or patterns.ALL

  local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"
  cmd = cmd .. " --glob '**/*.ts'"
  cmd = cmd .. " --glob '**/*.js'"
  cmd = cmd .. " --glob '!**/node_modules/**'"
  cmd = cmd .. " --glob '!**/dist/**'"

  -- Add patterns
  for _, pattern in ipairs(method_patterns) do
    cmd = cmd .. " -e '" .. pattern .. "'"
  end

  return cmd
end

-- Line parsing
---@param line string
---@param method string
---@return endpoint.entry|nil
function M.parse_line(line, method)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    return nil
  end

  -- Extract endpoint path
  local endpoint_path = M.extract_path(content)
  if not endpoint_path then
    return nil
  end

  -- Get controller base path
  local controller_path = M.get_controller_path(file_path)
  local full_path = M.combine_paths(controller_path, endpoint_path)

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

-- Extract path from NestJS decorators
---@param content string
---@return string|nil
function M.extract_path(content)
  -- @Get('path'), @Post("path"), etc.
  local path = content:match "@%w+%s*%(%s*[\"']([^\"']+)[\"']"
  if path then
    -- Ensure path starts with /
    if not path:match "^/" then
      return "/" .. path
    end
    return path
  end

  -- @Get() without parameter - root path
  local decorator_match = content:match "@(%w+)%s*%(%s*%)"
  if decorator_match then
    return "/" -- Root path for this controller
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

  -- Extract from decorator
  local method = content:match "@(%w+)%s*%("
  if method then
    return method:upper()
  end

  return "GET"
end

-- Get controller base path from @Controller decorator
---@param file_path string
---@return string
function M.get_controller_path(file_path)
  local file = io.open(file_path, "r")
  if not file then
    return ""
  end

  local content = file:read "*all"
  file:close()

  -- Look for @Controller('path') decorator
  local controller_path = content:match "@Controller%s*%(%s*[\"']([^\"']*)[\"']"
  if controller_path then
    -- Ensure path starts with /
    if not controller_path:match "^/" then
      return "/" .. controller_path
    end
    return controller_path
  end

  -- @Controller() without parameter - no base path
  if content:match "@Controller%s*%(%s*%)" then
    return ""
  end

  return ""
end

-- Combine controller path with endpoint path
---@param base string|nil
---@param endpoint string|nil
---@return string
function M.combine_paths(base, endpoint)
  if not base or base == "" then
    return endpoint or "/"
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
