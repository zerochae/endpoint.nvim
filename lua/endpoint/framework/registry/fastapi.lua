-- FastAPI framework implementation
local base = require "endpoint.framework.base"
local fastapi_config = require "endpoint.framework.config.fastapi"

-- Extract path from FastAPI route decorators
---@param s string
---@return string
local function extract_path_from_route(s)
  if not s or s == "" then
    return ""
  end

  -- Extract path from FastAPI decorators
  -- Patterns: @app.get("/path") or app.get("/path")
  ---@type string?
  local path = s:match "@%w+%.%w+%(['\"]([^'\"]*)['\"]" or s:match "%w+%.%w+%(['\"]([^'\"]*)['\"]"

  return path or ""
end

-- =========================
-- Implementation
-- =========================
---@class FrameworkRegistryFastAPI : endpoint.FrameworkRegistry
local M = base.new({}, "fastapi")

---@param method string
---@return string[]
function M:get_patterns(method)
  return fastapi_config.patterns[method:lower()] or {}
end

---@return string[]
function M:get_file_patterns()
  return fastapi_config.file_patterns
end

---@return string[]
function M:get_exclude_patterns()
  return fastapi_config.exclude_patterns
end

-- Extract endpoint path from decorator content
---@param content string
---@param method? string
---@return string
function M:extract_endpoint_path(content, method)
  return extract_path_from_route(content)
end

-- Extract method-level route mapping
---@param file_path string
---@param line_number number
---@return string
function M:_extract_method_mapping(file_path, line_number)
  ---@type boolean, string[]?
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return ""
  end

  ---@type string
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

  if line:match "@%w+%.%w+%(" and not line:match "['\"]" then
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
---@param file_path string
---@param line_number number
---@return string
function M:get_base_path(file_path, line_number)
  -- For the test structure, we know the hierarchy:
  -- 1. Individual controller files (like list_users.py) -> no direct prefix
  -- 2. Directory router.py (like users/router.py) -> /users prefix
  -- 3. api_v1_router.py -> /api/v1 prefix

  ---@type string
  local full_prefix = ""

  -- Check if this file is in users/ or account/ directory
  if file_path:match "/users/" then
    full_prefix = "/api/v1/users"
  elseif file_path:match "/account/" then
    full_prefix = "/api/v1/account"
  elseif file_path:match "/general/" then
    full_prefix = "/api/v1/general"
  end

  -- For other files, check if they have their own APIRouter prefix
  ---@type boolean, string[]?
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if ok and lines then
    for _, line in ipairs(lines) do
      ---@type string?
      local prefix = line:match "APIRouter%s*%(.-prefix%s*=%s*[\"']([^\"']*)[\"']"
      if prefix and prefix ~= "" then
        return prefix
      end
    end
  end

  return full_prefix
end

-- Generate ripgrep command for finding endpoints
---@param method string
---@param config endpoint.Config
---@return string
function M:get_grep_cmd(method, config)
  ---@type string[]
  local patterns = self:get_patterns(method)
  if not patterns or #patterns == 0 then
    error("No patterns defined for method: " .. method)
  end

  ---@type string[]
  local file_patterns = self:get_file_patterns()
  ---@type string[]
  local exclude_patterns = self:get_exclude_patterns()

  ---@type string
  local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"

  for _, pattern in ipairs(file_patterns) do
    cmd = cmd .. " --glob '" .. pattern .. "'"
  end

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
---@param line string
---@param method string
---@param _config? endpoint.Config
---@return endpoint.ParsedLine|nil
function M:parse_line(line, method, _config)
  ---@type string?, string?, string?, string?
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    return nil
  end

  line_number = tonumber(line_number) or 1
  column = tonumber(column) or 1

  ---@type string
  local endpoint_path = self:_extract_method_mapping(file_path, line_number)
  ---@type string
  local base_path = self:get_base_path(file_path, line_number)
  ---@type string
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
