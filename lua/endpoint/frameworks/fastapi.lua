local Framework = require "endpoint.core.Framework"
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
    search_options = { "--case-sensitive", "--type", "py", "-U", "--multiline-dotall" },
    controller_extractors = {
      {
        pattern = "([^/]+)%.py$",
        transform = function(name)
          return name:gsub("_controller$", ""):gsub("_router$", ""):gsub("_api$", "")
        end,
      },
    },
    detector = {
      dependencies = { "fastapi", "FastAPI" },
      manifest_files = { "requirements.txt", "pyproject.toml", "setup.py", "Pipfile" },
      name = "fastapi_dependency_detection",
    },
    parser = FastApiParser,
  })
  setmetatable(fastapi_framework_instance, self)
  return fastapi_framework_instance
end

return FastApiFramework
