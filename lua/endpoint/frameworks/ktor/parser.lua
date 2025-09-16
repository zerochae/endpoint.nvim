local utils = require "endpoint.frameworks.ktor.utils"

return function(content, file_path, line_number, column, framework_opts)
  -- Extract HTTP method and path from various Ktor patterns
  local http_method, endpoint_path = utils.extract_route_info(content, "ALL", file_path, line_number)
  if not http_method or not endpoint_path then
    return nil
  end

  return {
    method = http_method,
    endpoint_path = endpoint_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = http_method .. " " .. endpoint_path,
    confidence = 0.8,
    tags = { "api", "ktor" },
    framework = framework_opts.name,
    metadata = {
      nested_routing = endpoint_path:match("/.*/.+") and true or false,
    }
  }
end