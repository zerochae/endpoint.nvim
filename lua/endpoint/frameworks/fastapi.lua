-- FastAPI Framework Implementation (Function-based)
local M = {}

-- Detection
function M.detect()
  -- Check for FastAPI-related files
  if vim.fn.filereadable("requirements.txt") == 1 then
    local content = vim.fn.readfile("requirements.txt")
    for _, line in ipairs(content) do
      if line:match("fastapi") then
        return true
      end
    end
  end
  
  if vim.fn.filereadable("pyproject.toml") == 1 then
    local content = vim.fn.readfile("pyproject.toml")
    for _, line in ipairs(content) do
      if line:match("fastapi") then
        return true
      end
    end
  end
  
  return false
end

-- Search command generation
function M.get_search_cmd(method)
  local patterns = {
    GET = { "@app\\.get", "@router\\.get" },
    POST = { "@app\\.post", "@router\\.post" },
    PUT = { "@app\\.put", "@router\\.put" },
    DELETE = { "@app\\.delete", "@router\\.delete" },
    PATCH = { "@app\\.patch", "@router\\.patch" },
    ALL = { "@app\\.(get|post|put|delete|patch)", "@router\\.(get|post|put|delete|patch)" },
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

-- Extract path from FastAPI decorators
function M.extract_path(content)
  -- @app.get("/path"), @router.post("/path"), etc.
  local path = content:match('@[^%.]+%.%w+%s*%(%s*["\']([^"\']+)["\']')
  if path then return path end
  
  return nil
end

-- Extract HTTP method
function M.extract_method(content, search_method)
  -- If searching for specific method, return it
  if search_method ~= "ALL" then
    return search_method:upper()
  end
  
  -- Extract from decorator
  local method = content:match('@[^%.]+%.(%w+)%s*%(')
  if method then
    return method:upper()
  end
  
  return "GET"
end

return M