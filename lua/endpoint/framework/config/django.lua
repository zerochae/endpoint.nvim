return {
  file_patterns = { "**/*.py" },
  exclude_patterns = { "**/__pycache__/**", "**/venv/**", "**/env/**" },
  detection_files = { "manage.py", "requirements.txt", "pyproject.toml" },
  patterns = {
    get = { "def.*get.*\\(", "path\\(.*view.*get" },
    post = { "def.*post.*\\(", "path\\(.*view.*post" },
    put = { "def.*put.*\\(", "path\\(.*view.*put" },
    delete = { "def.*delete.*\\(", "path\\(.*view.*delete" },
    patch = { "def.*patch.*\\(", "path\\(.*view.*patch" },
    all = { "def.*", "path\\(" },
  },
}
