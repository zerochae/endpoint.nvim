-- NestJS Framework Utility Functions
---@class endpoint.frameworks.nestjs.utils
local M = {}

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
---@return string|nil
function M.extract_method(content)
  -- Only match HTTP method decorators, not parameter decorators
  local valid_methods = {
    Get = "GET",
    Post = "POST",
    Put = "PUT",
    Delete = "DELETE",
    Patch = "PATCH",
    Options = "OPTIONS",
    Head = "HEAD",
  }

  local method = content:match "@(%w+)%s*%("
  if method and valid_methods[method] then
    return valid_methods[method]
  end

  return nil
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