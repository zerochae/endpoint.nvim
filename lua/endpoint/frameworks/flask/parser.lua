-- Flask Framework Parser
local utils = require "endpoint.frameworks.flask.utils"

---@param content string The matched line content
---@param file_path string The file path
---@param line_number number The line number
---@param column number The column number
---@param framework_opts any Framework options
---@return endpoint.entry[] entries Array of endpoint entries
return function(content, file_path, line_number, column, framework_opts)
  -- Extract endpoint path from Flask decorators
  local endpoint_path = utils.extract_path(content)
  if not endpoint_path then
    return {}
  end

  -- Extract HTTP method from Flask route
  local parsed_method = utils.extract_method(content)
  if not parsed_method then
    return {}
  end

  -- Return endpoint.entry
  return {
    {
      method = parsed_method,
      endpoint_path = endpoint_path,
      file_path = file_path,
      line_number = line_number,
      column = column,
      display_value = parsed_method .. " " .. endpoint_path,
      confidence = 0.9,
      tags = { "api", "flask" },
      framework = framework_opts.name,
    },
  }
end