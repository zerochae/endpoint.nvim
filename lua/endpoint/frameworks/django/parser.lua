-- Django Framework Parser
local utils = require "endpoint.frameworks.django.utils"

---@param content string[] Array of file content lines
---@param file_path string The file path
---@param framework_opts any Framework options
---@return endpoint.entry[] entries Array of endpoint entries
return function(content, file_path, framework_opts)
  local endpoints = {}

  -- Extract URL patterns from urls.py
  local url_patterns = utils.extract_url_patterns(content)

  for _, pattern in ipairs(url_patterns) do
    if pattern.pattern and pattern.view then
      -- Normalize the URL path
      local normalized_path = utils.normalize_path(pattern.pattern)

      -- Determine HTTP methods for this view
      local http_methods = utils.determine_http_methods(pattern.view)

      -- Create endpoint entries for each HTTP method
      for _, method in ipairs(http_methods) do
        table.insert(endpoints, {
          method = method,
          endpoint_path = normalized_path,
          file_path = file_path,
          line_number = pattern.file_line or 1,
          column = 1,
          display_value = method .. " " .. normalized_path,
          confidence = 0.8, -- Lower confidence for inferred methods
          tags = { "api", "django" },
          framework = framework_opts.name,
          metadata = {
            view = pattern.view,
            name = pattern.name,
            raw_pattern = pattern.pattern,
          }
        })
      end
    end
  end

  return endpoints
end