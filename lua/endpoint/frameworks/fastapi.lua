local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
local FastApiParser = require "endpoint.parser.fastapi_parser"

---@class endpoint.FastApiFramework
local FastApiFramework = setmetatable({}, { __index = Framework })
FastApiFramework.__index = FastApiFramework

---Creates a new FastApiFramework instance
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
    search_options = { "--case-sensitive", "--type", "py" },
  })
  setmetatable(fastapi_framework_instance, self)
  return fastapi_framework_instance
end

---Sets up detection and parsing for FastAPI
function FastApiFramework:_initialize()
  -- Setup detector
  self.detector = DependencyDetector:new(
    { "fastapi", "FastAPI" },
    { "requirements.txt", "pyproject.toml", "setup.py", "Pipfile" },
    "fastapi_dependency_detection"
  )

  -- Setup FastAPI-specific parser
  self.parser = FastApiParser:new()
end

---Detects if FastAPI is present in the current project
function FastApiFramework:detect()
  if not self.detector then
    self:_initialize()
  end
  if self.detector then
    return self.detector:is_target_detected()
  end
  return false
end

---Extract controller name from FastAPI file path
function FastApiFramework:getControllerName(file_path)
  -- FastAPI: controllers/users/create_user.py → users or routers/api/v1/users.py → users
  local name = file_path:match "([^/]+)%.py$"
  if name then
    -- Remove common suffixes and convert to readable name
    return name:gsub("_controller$", ""):gsub("_router$", ""):gsub("_api$", "")
  end
  return nil
end

return FastApiFramework
