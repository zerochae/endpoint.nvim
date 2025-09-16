-- Django Framework Module
local framework = require "endpoint.framework"

---@type endpoint.framework_base
return framework:new("django"):setup {
  file_extensions = { "*.py" },
  exclude_patterns = {
    "**/migrations/**",
    "**/__pycache__/**",
    "**/venv/**",
    "**/env/**",
    "**/.venv/**"
  },
  detection = {
    files = { "manage.py", "settings.py", "urls.py" },
    dependencies = { "Django", "django" },
    manifest_files = { "requirements.txt", "pyproject.toml", "Pipfile" },
  },
  type = "structure",
  target_files = { "urls.py" },
  parser = require "endpoint.frameworks.django.parser",
}