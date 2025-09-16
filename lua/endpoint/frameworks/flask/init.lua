-- Flask Framework Module
local framework = require "endpoint.framework"

---@type endpoint.framework_base
return framework:new("flask"):setup {
  file_extensions = { "*.py" },
  exclude_patterns = { "**/__pycache__/**", "**/venv/**" },
  detection = {
    files = { "app.py", "main.py", "run.py" },
    dependencies = { "flask" },
    manifest_files = { "requirements.txt", "pyproject.toml", "setup.py" },
  },
  type = "pattern",
  patterns = {
    GET = { "@app%.route", "@bp%.route", "@blueprint%.route" },
    POST = { "@app%.route", "@bp%.route", "@blueprint%.route" },
    PUT = { "@app%.route", "@bp%.route", "@blueprint%.route" },
    DELETE = { "@app%.route", "@bp%.route", "@blueprint%.route" },
    PATCH = { "@app%.route", "@bp%.route", "@blueprint%.route" },
  },
  parser = require "endpoint.frameworks.flask.parser",
}