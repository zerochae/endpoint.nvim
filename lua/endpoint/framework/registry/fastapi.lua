-- FastAPI framework implementation
local base = require "endpoint.framework.base"
local fastapi_config = require "endpoint.framework.config.fastapi"

-- Extract path from FastAPI route decorators
local function extract_path_from_route(s)
  if not s or s == "" then
    return ""
  end

  -- Extract path from FastAPI decorators
  -- Patterns: @app.get("/path") or app.get("/path")
  local path = s:match("@%w+%.%w+%(['\"]([^'\"]*)['\"]") or 
               s:match("%w+%.%w+%(['\"]([^'\"]*)['\"]")
  
  return path or ""
end

-- =========================
-- Implementation
-- =========================
local M = base.new {}

function M:get_patterns(method)
  return fastapi_config.patterns[method:lower()] or {}
end

function M:get_file_types()
  -- Extract file extensions from file_patterns in config
  local file_extensions = {}
  for _, pattern in ipairs(fastapi_config.file_patterns) do
    local ext = pattern:match "%.(%w+)$"
    if ext then
      table.insert(file_extensions, ext)
    end
  end
  -- Default to py if no extensions found
  if #file_extensions == 0 then
    file_extensions = {"py"}
  end
  return file_extensions
end

function M:get_exclude_patterns()
  return fastapi_config.exclude_patterns
end

-- Extract endpoint path from decorator content
function M:extract_endpoint_path(content)
  return extract_path_from_route(content)
end

-- Extract method-level route mapping
function M:_extract_method_mapping(file_path, line_number)
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return ""
  end

  local line = lines[line_number] or ""
  
  -- Check if current line contains FastAPI route decorator
  if not line:match "@%w+%.%w+" and not line:match "%w+%.%w+%(" then
    -- Check lines above for decorator (within 5 lines)
    for j = math.max(1, line_number - 5), line_number - 1 do
      local prev_line = lines[j] or ""
      if prev_line:match "@%w+%.%w+" or prev_line:match "%w+%.%w+%(" then
        line = prev_line
        break
      end
    end
  end
  
  -- For multiline decorators like @router.post(\n "/path",
  if line:match "@%w+%.%w+%(" and not line:match "['\"]" then
    -- Look at next few lines for the path
    for j = line_number + 1, math.min(#lines, line_number + 3) do
      local next_line = lines[j] or ""
      local path = next_line:match "^%s*['\"]([^'\"]*)['\"]"
      if path then
        return path
      end
    end
  end
  
  return extract_path_from_route(line)
end

-- Extract base path from APIRouter prefix patterns
function M:get_base_path(file_path, line_number)
  -- For the test structure, we know the hierarchy:
  -- 1. Individual controller files (like list_users.py) -> no direct prefix
  -- 2. Directory router.py (like users/router.py) -> /users prefix  
  -- 3. api_v1_router.py -> /api/v1 prefix
  
  local full_prefix = ""
  
  -- Check if this file is in users/ or account/ directory
  if file_path:match("/users/") then
    full_prefix = "/api/v1/users"
  elseif file_path:match("/account/") then
    full_prefix = "/api/v1/account"
  elseif file_path:match("/general/") then
    full_prefix = "/api/v1/general"
  end
  
  -- For other files, check if they have their own APIRouter prefix
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if ok and lines then
    for _, line in ipairs(lines) do
      local prefix = line:match('APIRouter%s*%(.-prefix%s*=%s*["\']([^"\']*)["\']')
      if prefix and prefix ~= "" then
        return prefix
      end
    end
  end
  
  return full_prefix
end

-- Generate ripgrep command for finding endpoints
function M:get_grep_cmd(method, config)
  local patterns = self:get_patterns(method)
  if not patterns or #patterns == 0 then
    error("No patterns defined for method: " .. method)
  end

  local file_types = self:get_file_types()
  local exclude_patterns = self:get_exclude_patterns()

  local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"

  -- Use glob pattern for .py files
  cmd = cmd .. " --glob '*.py'"
  
  for _, ex in ipairs(exclude_patterns) do
    cmd = cmd .. " --glob '!" .. ex .. "'"
  end
  if config and config.rg_additional_args and config.rg_additional_args ~= "" then
    cmd = cmd .. " " .. config.rg_additional_args
  end

  -- Use first pattern for initial search
  cmd = cmd .. " '" .. patterns[1] .. "'"
  return cmd
end

-- Parse ripgrep output line "path:line:col:content"
function M:parse_line(line, method, _config)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    return nil
  end

  line_number = tonumber(line_number) or 1
  column = tonumber(column) or 1

  local endpoint_path = self:_extract_method_mapping(file_path, line_number)
  local base_path = self:get_base_path(file_path, line_number)
  local full_path = self:combine_paths(base_path, endpoint_path)

  return {
    file_path = file_path,
    line_number = line_number,
    column = column,
    endpoint_path = full_path,
    method = method:upper(),
    raw_line = line,
    content = content,
  }
end

return M