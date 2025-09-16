local utils = require "endpoint.frameworks.phoenix.utils"

return function(content, file_path, line_number, column, framework_opts)
  local endpoint_path = utils.extract_path(content)
  if not endpoint_path then return {} end

  local parsed_method = utils.extract_method(content)
  if not parsed_method then return {} end

  return {{
    method = parsed_method,
    endpoint_path = endpoint_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = parsed_method .. " " .. endpoint_path,
    confidence = 0.9,
    tags = { "api", "phoenix" },
    framework = framework_opts.name,
  }}
end