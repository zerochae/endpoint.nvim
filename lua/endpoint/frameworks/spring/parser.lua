local utils = require "endpoint.frameworks.spring.utils"

---@param content string The matched line content
---@param file_path string The file path
---@param line_number number The line number
---@param column number The column number
---@param framework_opts any Framework options
---@return endpoint.entry[] entries Array of endpoint entries
return function(content, file_path, line_number, column, framework_opts)
  -- Extract endpoint path from various Spring annotations
  local endpoint_path = utils.extract_path(content)
  if not endpoint_path then
    return {}
  end

  -- Try to get base path from class-level @RequestMapping
  local base_path = utils.get_base_path(file_path, line_number)
  local full_path = utils.combine_paths(base_path, endpoint_path)

  -- Extract HTTP method from annotation
  local parsed_method = utils.extract_method(content)
  if not parsed_method then
    return {}
  end

  -- Return endpoint.entry
  return {
    {
      method = parsed_method,
      endpoint_path = full_path,
      file_path = file_path,
      line_number = line_number,
      column = column,
      display_value = parsed_method .. " " .. full_path,
      confidence = 0.9,
      tags = { "api", "spring" },
      framework = framework_opts.name,
    },
  }
end

