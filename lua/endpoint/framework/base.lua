local core_base = require "endpoint.core.base"

-- Required methods that framework implementations must provide
local required_methods = {
  "get_patterns",
  "get_file_patterns",
  "get_exclude_patterns",
  "extract_endpoint_path",
  "get_base_path",
}

-- Optional methods with default implementations
local optional_methods = {
  prefer_single_pattern = function()
    return false
  end,
  can_handle = function()
    return true
  end,
}

-- Create base class for frameworks
local M = core_base.create_base(required_methods, optional_methods)

-- Framework-specific methods
function M:get_grep_cmd(method, config)
  local patterns = self:get_patterns(method)
  if not patterns or #patterns == 0 then
    self:error("No patterns defined for method: " .. method)
  end

  local exclude_patterns = self:get_exclude_patterns()

  local cmd = "rg"
  cmd = cmd .. " --line-number --column --no-heading --color=never"
  cmd = cmd .. " --case-sensitive"

  local file_patterns = self:get_file_patterns()
  for _, pattern in ipairs(file_patterns) do
    cmd = cmd .. " --glob '" .. pattern .. "'"
  end

  for _, pattern in ipairs(exclude_patterns) do
    cmd = cmd .. " --glob '!" .. pattern .. "'"
  end

  if config and config.rg_additional_args and config.rg_additional_args ~= "" then
    cmd = cmd .. " " .. config.rg_additional_args
  end

  local pattern_str = table.concat(patterns, " -e ")
  cmd = cmd .. " -e '" .. pattern_str .. "'"

  return cmd
end

function M:parse_line(line, method)
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"

  if not file_path or not line_number or not column or not content then
    return nil
  end

  local endpoint_path = self:extract_endpoint_path(content, method)
  local base_path = self:get_base_path(file_path, tonumber(line_number))
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

  if base:sub(-1) == "/" then
    base = base:sub(1, -2)
  end
  if endpoint:sub(1, 1) ~= "/" then
    endpoint = "/" .. endpoint
  end

  return base .. endpoint
end

return M

