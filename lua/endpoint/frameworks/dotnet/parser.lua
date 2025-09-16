-- .NET Framework Parser
local utils = require "endpoint.frameworks.dotnet.utils"

---@param content string The matched line content
---@param file_path string The file path
---@param line_number number The line number
---@param column number The column number
---@param framework_opts any Framework options
---@return endpoint.entry|nil entry Single endpoint entry or nil
return function(content, file_path, line_number, column, framework_opts)
  -- Extract HTTP method and path from various .NET patterns
  local http_method, endpoint_path = utils.extract_route_info(content, "ALL")
  if not http_method or not endpoint_path then
    return nil
  end

  -- Try to get base path from controller-level [Route] attribute or controller name
  local base_path = utils.get_base_path(file_path, line_number)
  local full_path = utils.combine_paths(base_path, endpoint_path)

  return {
    method = http_method,
    endpoint_path = full_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = http_method .. " " .. full_path,
    confidence = 0.9,
    tags = { "api", "dotnet" },
    framework = framework_opts.name,
    metadata = {
      base_path = base_path,
      endpoint_path = endpoint_path,
    }
  }
end