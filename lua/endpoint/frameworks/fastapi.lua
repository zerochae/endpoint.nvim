local Framework = require "endpoint.core.Framework"
local DependencyDetectionStrategy = require "endpoint.core.strategies.detection.DependencyDetectionStrategy"
local AnnotationParsingStrategy = require "endpoint.core.strategies.parsing.AnnotationParsingStrategy"

---@class FastApiFramework : Framework
local FastApiFramework = setmetatable({}, { __index = Framework })
FastApiFramework.__index = FastApiFramework

---Creates a new FastApiFramework instance
---@return FastApiFramework
function FastApiFramework:new()
  local fastapi_framework_instance = Framework.new(self, "fastapi", {
    file_extensions = { "*.py" },
    exclude_patterns = { "**/__pycache__", "**/venv", "**/.venv", "**/site-packages" },
    patterns = {
      GET = { "@app\\.get", "@router\\.get" },
      POST = { "@app\\.post", "@router\\.post" },
      PUT = { "@app\\.put", "@router\\.put" },
      DELETE = { "@app\\.delete", "@router\\.delete" },
      PATCH = { "@app\\.patch", "@router\\.patch" },
    },
    search_options = { "--type", "py" }
  })
  setmetatable(fastapi_framework_instance, self)
  ---@cast fastapi_framework_instance FastApiFramework
  return fastapi_framework_instance
end

---Sets up detection and parsing strategies for FastAPI
---@protected
function FastApiFramework:_setup_strategies()
  -- Setup detection strategy
  self.detection_strategy = DependencyDetectionStrategy:new(
    { "fastapi", "FastAPI" },
    { "requirements.txt", "pyproject.toml", "setup.py", "Pipfile" },
    "fastapi_dependency_detection"
  )

  -- Setup parsing strategy with FastAPI annotation patterns
  local fastapi_annotation_patterns = {
    GET = { "@app%.get", "@router%.get" },
    POST = { "@app%.post", "@router%.post" },
    PUT = { "@app%.put", "@router%.put" },
    DELETE = { "@app%.delete", "@router%.delete" },
    PATCH = { "@app%.patch", "@router%.patch" },
    OPTIONS = { "@app%.options", "@router%.options" },
    HEAD = { "@app%.head", "@router%.head" }
  }

  local fastapi_path_extraction_patterns = {
    '%("([^"]+)"[^)]*%)',   -- @app.get("/path")
    "%('([^']+)'[^)]*%)",   -- @app.get('/path')
    '%(f?"([^"]+)"[^)]*%)', -- @app.get(f"/path")
    "%(f?'([^']+)'[^)]*%)"  -- @app.get(f'/path')
  }

  local fastapi_method_mapping = {
    ["@app%.get"] = "GET",
    ["@router%.get"] = "GET",
    ["@app%.post"] = "POST",
    ["@router%.post"] = "POST",
    ["@app%.put"] = "PUT",
    ["@router%.put"] = "PUT",
    ["@app%.delete"] = "DELETE",
    ["@router%.delete"] = "DELETE",
    ["@app%.patch"] = "PATCH",
    ["@router%.patch"] = "PATCH"
  }

  self.parsing_strategy = AnnotationParsingStrategy:new(
    fastapi_annotation_patterns,
    fastapi_path_extraction_patterns,
    fastapi_method_mapping
  )
end

---Detects if FastAPI is present in the current project
---@return boolean
function FastApiFramework:detect()
  return self.detection_strategy:is_target_detected()
end

---Parses FastAPI content to extract endpoint information
---@param content string The content to parse
---@param file_path string Path to the file
---@param line_number number Line number in the file
---@param column number Column number in the line
---@return endpoint.entry|nil
function FastApiFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parsing_strategy:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- Enhance with FastAPI-specific metadata
    parsed_endpoint.tags = parsed_endpoint.tags or {}
    table.insert(parsed_endpoint.tags, "python")
    table.insert(parsed_endpoint.tags, "fastapi")

    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "fastapi"
    parsed_endpoint.metadata.language = "python"
  end

  return parsed_endpoint
end

return FastApiFramework