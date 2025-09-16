local utils = require "endpoint.frameworks.symfony.utils"

return function(content, file_path, line_number, column, framework_opts)
  -- Skip controller-level @Route (without methods parameter)
  if utils.is_controller_level_route(content) then
    return nil
  end

  -- Extract endpoint path
  local endpoint_path = utils.extract_path(content)
  if not endpoint_path then
    return nil
  end

  -- Try to get base path from controller-level @Route
  local base_path = utils.get_base_path(file_path, line_number)
  local full_path = utils.combine_paths(base_path, endpoint_path)

  -- Extract HTTP method (use first method if multiple)
  local parsed_method = utils.extract_method(content)
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
    tags = { "api", "symfony" },
    framework = framework_opts.name,
    metadata = {
      base_path = base_path,
      endpoint_path = endpoint_path,
    }
  }
end