-- Base framework implementation with common logic
local M = {}
M.__index = M

-- Default implementation for the framework interface

-- Creates a new framework object that inherits from this base
function M.new(implementation)
  setmetatable(implementation, M)
  return implementation
end

function M:prefer_single_pattern()
  return false
end

-- Generic grep command builder
-- This can be used by specific frameworks if they provide the necessary methods
function M:get_grep_cmd(method, config)
  local patterns = self:get_patterns(method)
  if not patterns or #patterns == 0 then
    error("No patterns defined for method: " .. method)
  end

  local exclude_patterns = self:get_exclude_patterns()

  local cmd = "rg"
  cmd = cmd .. " --line-number --column --no-heading --color=never"
  cmd = cmd .. " --case-sensitive"

  -- Add file pattern constraints using glob
  local file_patterns = self:get_file_patterns()
  for _, pattern in ipairs(file_patterns) do
    cmd = cmd .. " --glob '" .. pattern .. "'"
  end

  -- Add exclude patterns
  for _, pattern in ipairs(exclude_patterns) do
    cmd = cmd .. " --glob '!" .. pattern .. "'"
  end

  -- Add additional ripgrep args if configured
  if config and config.rg_additional_args and config.rg_additional_args ~= "" then
    cmd = cmd .. " " .. config.rg_additional_args
  end

  -- Add search patterns
  local pattern_str = table.concat(patterns, " -e ")
  cmd = cmd .. " -e '" .. pattern_str .. "'"

  return cmd
end

-- Generic line parser for "filepath:line:column:content" format
function M:parse_line(line, method)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"

  if not file_path or not line_number or not column or not content then
    return nil
  end

  -- The specific endpoint path extraction is left to the implementation
  local endpoint_path = self:extract_endpoint_path(content, method)

  -- The base path extraction is also specific
  local base_path = self:get_base_path(file_path, tonumber(line_number))

  -- Combine paths
  local full_path = self:combine_paths(base_path, endpoint_path)

  return {
    file_path = file_path,
    line_number = tonumber(line_number),
    column = tonumber(column),
    endpoint_path = full_path,
    method = method:upper(),
    raw_line = line,
    content = content,
  }
end

-- Default path combiner
function M:combine_paths(base, endpoint)
  if not base or base == "" then
    return endpoint
  end
  if not endpoint or endpoint == "" then
    return base
  end

  -- If base exists and endpoint is just "/", return base without trailing slash
  if endpoint == "/" and base ~= "" then
    return base
  end

  -- Avoid double slashes
  if base:sub(-1) == "/" then
    base = base:sub(1, -2)
  end
  if endpoint:sub(1, 1) ~= "/" then
    endpoint = "/" .. endpoint
  end

  return base .. endpoint
end

-- Methods that MUST be implemented by the specific framework
function M:get_patterns(method)
  error "get_patterns(method) must be implemented by the framework"
end

function M:get_file_patterns()
  error "get_file_patterns() must be implemented by the framework"
end

function M:get_exclude_patterns()
  error "get_exclude_patterns() must be implemented by the framework"
end

function M:extract_endpoint_path(content, method)
  error "extract_endpoint_path(content, method) must be implemented by the framework"
end

function M:get_base_path(file_path, line_number)
  error "get_base_path(file_path, line_number) must be implemented by the framework"
end

return M
