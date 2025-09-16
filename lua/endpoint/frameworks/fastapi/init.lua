-- FastAPI Framework Module
local framework = require "endpoint.framework"

---@type endpoint.framework_base
return framework:new("fastapi"):setup {
  file_extensions = { "*.py" },
  exclude_patterns = { "**/__pycache__/**", "**/venv/**" },
  detection = {
    files = { "main.py", "app.py" },
    dependencies = { "fastapi" },
    manifest_files = { "requirements.txt", "pyproject.toml", "setup.py" },
  },
  type = "pattern",
  patterns = {
    GET = { "@app\\.get", "@router\\.get" },
    POST = { "@app\\.post", "@router\\.post" },
    PUT = { "@app\\.put", "@router\\.put" },
    DELETE = { "@app\\.delete", "@router\\.delete" },
    PATCH = { "@app\\.patch", "@router\\.patch" },
  },
  parser = require "endpoint.frameworks.fastapi.parser",
}