-- FastAPI Framework Parser
local utils = require "endpoint.frameworks.fastapi.utils"

---@param content string The matched line content
---@param file_path string The file path
---@param line_number number The line number
---@param column number The column number
---@param framework_opts any Framework options
---@return endpoint.entry|nil entry Single endpoint entry or nil
return function(content, file_path, line_number, column, framework_opts)
  -- Extract endpoint path (handle multiline decorators)
  local endpoint_path = utils.extract_path_multiline(file_path, line_number, content)
  if not endpoint_path then
    return nil
  end

  -- Try to get base path from router prefix
  local base_path = utils.get_base_path(file_path, line_number)
  local full_path = utils.combine_paths(base_path, endpoint_path)

  -- Extract HTTP method
  local parsed_method = utils.extract_method(content, "ALL")
  if not parsed_method then
    return nil
  end

  return {
    method = parsed_method,
    endpoint_path = full_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = parsed_method .. " " .. full_path,
    confidence = 0.9,
    tags = { "api", "fastapi" },
    framework = framework_opts.name,
    metadata = {
      base_path = base_path,
      endpoint_path = endpoint_path,
    }
  }
end