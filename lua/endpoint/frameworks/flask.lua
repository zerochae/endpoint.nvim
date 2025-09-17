local Framework = require "endpoint.core.Framework"
local DependencyDetectionStrategy = require "endpoint.core.strategies.detection.DependencyDetectionStrategy"
local AnnotationParsingStrategy = require "endpoint.core.strategies.parsing.AnnotationParsingStrategy"

---@class endpoint.FlaskFramework : endpoint.Framework
local FlaskFramework = setmetatable({}, { __index = Framework })
FlaskFramework.__index = FlaskFramework

---Creates a new FlaskFramework instance
function FlaskFramework:new()
  local flask_framework_instance = Framework.new(self, "flask", {
    file_extensions = { "*.py" },
    exclude_patterns = { "**/__pycache__", "**/venv", "**/.venv", "**/site-packages" },
    patterns = {
      GET = { "@app\\.route", "@blueprint\\.route" },
      POST = { "@app\\.route", "@blueprint\\.route" },
      PUT = { "@app\\.route", "@blueprint\\.route" },
      DELETE = { "@app\\.route", "@blueprint\\.route" },
      PATCH = { "@app\\.route", "@blueprint\\.route" },
    },
    search_options = { "--type", "py" }
  })
  setmetatable(flask_framework_instance, self)
  ---@cast flask_framework_instance FlaskFramework
  return flask_framework_instance
end

---Sets up detection and parsing strategies for Flask
function FlaskFramework:_setup_strategies()
  -- Setup detection strategy
  self.detection_strategy = DependencyDetectionStrategy:new(
    { "flask", "Flask" },
    { "requirements.txt", "pyproject.toml", "setup.py", "Pipfile" },
    "flask_dependency_detection"
  )

  -- Setup parsing strategy with Flask route patterns
  local flask_annotation_patterns = {
    GET = { "@app%.route", "@blueprint%.route" },
    POST = { "@app%.route", "@blueprint%.route" },
    PUT = { "@app%.route", "@blueprint%.route" },
    DELETE = { "@app%.route", "@blueprint%.route" },
    PATCH = { "@app%.route", "@blueprint%.route" },
    OPTIONS = { "@app%.route", "@blueprint%.route" },
    HEAD = { "@app%.route", "@blueprint%.route" }
  }

  local flask_path_extraction_patterns = {
    '%("([^"]+)"[^)]*%)',   -- @app.route("/path")
    "%('([^']+)'[^)]*%)",   -- @app.route('/path')
    '%(f?"([^"]+)"[^)]*%)', -- @app.route(f"/path")
    "%(f?'([^']+)'[^)]*%)"  -- @app.route(f'/path')
  }

  local flask_method_mapping = {
    ["@app%.route"] = "GET", -- Default to GET, will be overridden by methods parameter
    ["@blueprint%.route"] = "GET"
  }

  self.parsing_strategy = AnnotationParsingStrategy:new(
    flask_annotation_patterns,
    flask_path_extraction_patterns,
    flask_method_mapping
  )
end

---Detects if Flask is present in the current project
function FlaskFramework:detect()
  return self.detection_strategy:is_target_detected()
end

---Parses Flask content to extract endpoint information
function FlaskFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parsing_strategy:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- Flask-specific method extraction from methods parameter
    local methods_match = content:match('methods%s*=%s*%[([^%]]+)%]')
    if methods_match then
      -- Extract first method from methods list
      local first_method = methods_match:match('["\']([^"\']+)["\']')
      if first_method then
        parsed_endpoint.method = first_method:upper()
        parsed_endpoint.display_value = parsed_endpoint.method .. " " .. parsed_endpoint.endpoint_path
      end
    end

    -- Enhance with Flask-specific metadata
    parsed_endpoint.tags = parsed_endpoint.tags or {}
    table.insert(parsed_endpoint.tags, "python")
    table.insert(parsed_endpoint.tags, "flask")

    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "flask"
    parsed_endpoint.metadata.language = "python"
    parsed_endpoint.metadata.methods_parameter = methods_match
  end

  return parsed_endpoint
end

return FlaskFramework
