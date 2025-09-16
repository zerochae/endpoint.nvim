local utils = require "endpoint.frameworks.nestjs.utils"

return function(content, file_path, line_number, column, framework_opts)
  local parsed_method = utils.extract_method(content)
  if not parsed_method then return nil end

  local endpoint_path = utils.extract_path(content)
  if not endpoint_path then return nil end

  -- Get controller base path and combine with endpoint path
  local controller_path = utils.get_controller_path(file_path)
  local full_path = utils.combine_paths(controller_path, endpoint_path)

  return {
    method = parsed_method,
    endpoint_path = full_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = parsed_method .. " " .. full_path,
    confidence = 0.9,
    tags = { "api", "nestjs" },
    framework = framework_opts.name,
    metadata = {
      controller_path = controller_path,
      endpoint_path = endpoint_path,
    }
  }
end