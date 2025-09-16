local utils = require "endpoint.frameworks.servlet.utils"

return function(content, file_path, line_number, column, framework_opts)
  -- Extract servlet path with file_path for complex lookups
  local servlet_path = utils.extract_path(content, file_path)
  if not servlet_path then
    return nil
  end

  -- Extract HTTP method
  local servlet_method = utils.extract_method(content)
  if not servlet_method then
    return nil
  end

  return {
    method = servlet_method,
    endpoint_path = servlet_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = servlet_method .. " " .. servlet_path,
    confidence = 0.7,
    tags = { "api", "servlet" },
    framework = framework_opts.name,
    metadata = {
      servlet_type = content:match "<servlet%-class>" and "xml" or "annotation"
    }
  }
end