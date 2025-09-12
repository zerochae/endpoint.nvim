-- NestJS Framework Implementation (Function-based)
local M = {}

-- Detection
function M.detect()
  if vim.fn.filereadable("package.json") == 1 then
    local content = vim.fn.readfile("package.json")
    local package_str = table.concat(content, "\n")
    if package_str:match("@nestjs") then
      return true
    end
  end
  
  return false
end

-- Search command generation
function M.get_search_cmd(method)
  local patterns = {
    GET = { "@Get", "@HttpCode.-@Get" },
    POST = { "@Post", "@HttpCode.-@Post" },
    PUT = { "@Put", "@HttpCode.-@Put" },
    DELETE = { "@Delete", "@HttpCode.-@Delete" },
    PATCH = { "@Patch", "@HttpCode.-@Patch" },
    ALL = { "@(Get|Post|Put|Delete|Patch)" },
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
function M.parse_line(line, method)
  local file_path, line_number, column, content = line:match("([^:]+):(%d+):(%d+):(.*)")
  if not file_path then return nil end
  
  -- Extract endpoint path
  local endpoint_path = M.extract_path(content)
  if not endpoint_path then return nil end
  
  -- Extract HTTP method
  local parsed_method = M.extract_method(content, method)
  
  return {
    file_path = file_path,
    line_number = tonumber(line_number),
    column = tonumber(column),
    method = parsed_method,
    endpoint_path = endpoint_path,
    display_value = parsed_method .. " " .. endpoint_path
  }
end

-- Extract path from NestJS decorators
function M.extract_path(content)
  -- @Get('path'), @Post("path"), etc.
  local path = content:match('@%w+%s*%(%s*["\']([^"\']+)["\']')
  if path then return path end
  
  -- @Get() without parameter - check controller path
  local decorator_match = content:match('@(%w+)%s*%(%s*%)')
  if decorator_match then
    return "/" -- Default path, will be combined with controller path
  end
  
  return nil
end

-- Extract HTTP method
function M.extract_method(content, search_method)
  -- If searching for specific method, return it
  if search_method ~= "ALL" then
    return search_method:upper()
  end
  
  -- Extract from decorator
  local method = content:match('@(%w+)%s*%(')
  if method then
    return method:upper()
  end
  
  return "GET"
end

return M