-- NestJS framework implementation
local base = require "endpoint.framework.base"
local nestjs_config = require "endpoint.framework.config.nestjs"

-- Create a new NestJS framework object inheriting from base
---@class FrameworkRegistryNestJS : endpoint.FrameworkRegistry
local M = {}

function M:is_available()
  return true
end

---@param method string
---@return string[]
function M:get_patterns(method)
  return nestjs_config.patterns[method:lower()] or {}
end

---@return string[]
function M:get_file_patterns()
  return nestjs_config.file_patterns
end

---@return string[]
function M:get_exclude_patterns()
  return nestjs_config.exclude_patterns
end

-- Extracts the endpoint path from the decorator content
---@param content string
---@param method? string
---@return string
function M:extract_endpoint_path(content, method)
  -- Look for path inside parentheses: @Get('/api/users'), @Get('api/users'), or @Get()
  local path = content:match "@%w+%s*%(%s*['\"]([^'\"]*)['\"]"
  if path == nil then
    -- Handle cases like @Get() - empty parentheses means root path
    if content:match "@%w+%s*%(%s*%)" then
      path = "/"
    else
      path = ""
    end
  elseif path == "" then
    -- Empty string in quotes like @Get("") also means root path
    path = "/"
  end
  return path
end

-- Override path combiner for NestJS specific behavior
---@param base string
---@param endpoint string
---@return string
function M:combine_paths(base, endpoint)
  -- If base is empty, just return endpoint (with leading slash if needed)
  if not base or base == "" then
    if not endpoint or endpoint == "" then
      return "/"
    end
    if endpoint:sub(1, 1) ~= "/" then
      return "/" .. endpoint
    end
    return endpoint
  end

  -- If endpoint is empty, just return base (with leading slash if needed)
  if not endpoint or endpoint == "" then
    if base:sub(1, 1) ~= "/" then
      return "/" .. base
    end
    return base
  end

  -- Both have content - combine them
  -- Remove trailing slash from base
  if base:sub(-1) == "/" then
    base = base:sub(1, -2)
  end

  -- Ensure base starts with slash
  if base:sub(1, 1) ~= "/" then
    base = "/" .. base
  end

  -- Add leading slash to endpoint if needed
  if endpoint:sub(1, 1) ~= "/" then
    endpoint = "/" .. endpoint
  end

  return base .. endpoint
end

-- Extracts base path from @Controller decorator at the class level
---@param file_path string
---@param line_number number
---@return string
function M:get_base_path(file_path, line_number)
  -- Try vim.fn.readfile first, then fallback to io.lines if needed
  ---@type string[]
  local lines = {}

  if vim and vim.fn and vim.fn.readfile then
    local ok, result = pcall(vim.fn.readfile, file_path)
    if ok and result and #result > 0 then
      lines = result
    else
      -- Fallback to io.lines even in vim environment if readfile fails
      local line_count = 0
      for line in io.lines(file_path) do
        line_count = line_count + 1
        lines[line_count] = line
      end
      if line_count == 0 then
        return ""
      end
    end
  else
    -- Fallback to io.lines for testing environments
    local line_count = 0
    for line in io.lines(file_path) do
      line_count = line_count + 1
      lines[line_count] = line
    end
    if line_count == 0 then
      return ""
    end
  end

  ---@type string
  local controller_path = ""
  -- Look backwards from the method line to find a class-level @Controller
  for i = line_number, 1, -1 do
    local line = lines[i] or ""

    if line:match "@Controller" then
      local path = line:match "@Controller%s*%(%s*['\"]([^'\"]*)['\"]" or ""
      controller_path = path
      break -- Found it
    end
    -- Stop if we hit an import, we've gone too far
    if line:match "^import " then
      break
    end
  end

  return controller_path
end

-- Override the default grep command builder to be simpler for NestJS
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
  local cmd = "rg"
  cmd = cmd .. " --line-number --column --no-heading --color=never"
  cmd = cmd .. " --case-sensitive"

  for _, pattern in ipairs(file_patterns) do
    cmd = cmd .. " --glob '" .. pattern .. "'"
  end

  for _, pattern in ipairs(exclude_patterns) do
    cmd = cmd .. " --glob '!" .. pattern .. "'"
  end

  if config and config.rg_additional_args and config.rg_additional_args ~= "" then
    cmd = cmd .. " " .. config.rg_additional_args
  end

  -- Use all patterns for comprehensive search
  if #patterns == 1 then
    cmd = cmd .. " '" .. patterns[1] .. "'"
  else
    -- Multiple patterns: use -e flag for each pattern
    for _, pattern in ipairs(patterns) do
      cmd = cmd .. " -e '" .. pattern .. "'"
    end
  end

  return cmd
end

-- Parse ripgrep line and combine base path with endpoint path
---@param line string
-- Extract actual HTTP method from NestJS decorators
local function extract_http_method_from_content(content)
  if content:match "@Get%(" then
    return "GET"
  elseif content:match "@Post%(" then
    return "POST"
  elseif content:match "@Put%(" then
    return "PUT"
  elseif content:match "@Delete%(" then
    return "DELETE"
  elseif content:match "@Patch%(" then
    return "PATCH"
  end
  return nil
end

---@param method string
---@return endpoint.ParsedLine|nil
function M:parse_line(line, method)
  ---@type string?, string?, string?, string?
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    return nil
  end

  line_number = tonumber(line_number) or 1
  column = tonumber(column) or 1

  ---@type string
  local endpoint_path = self:extract_endpoint_path(content, method)
  ---@type string
  local base_path = self:get_base_path(file_path, line_number)
  ---@type string
  local full_path = self:combine_paths(base_path, endpoint_path)

  -- Extract actual HTTP method if searching with ALL
  local actual_method = method:upper()
  if method:upper() == "ALL" then
    local detected_method = extract_http_method_from_content(content)
    if detected_method then
      actual_method = detected_method
    end
  end

  return {
    file_path = file_path,
    line_number = line_number,
    column = column,
    endpoint_path = full_path,
    method = actual_method,
    raw_line = line,
    content = content,
  }
end

return base.new(M, "nestjs")
