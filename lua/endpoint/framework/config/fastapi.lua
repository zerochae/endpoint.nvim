return {
  file_patterns = { "**/*.py" },
  exclude_patterns = { "**/venv/**", "**/__pycache__/**", "**/site-packages/**", "**/.pytest_cache/**" },
  detection_files = { "main.py", "requirements.txt", "pyproject.toml" },
  patterns = {
    get = {
      "@app\\.get",
      "@router\\.get",
      "app\\.get\\(",
      "router\\.get\\(",
    },
    post = {
      "@app\\.post",
      "@router\\.post",
      "app\\.post\\(",
      "router\\.post\\(",
    },
    put = {
      "@app\\.put",
      "@router\\.put",
      "app\\.put\\(",
      "router\\.put\\(",
    },
    delete = {
      "@app\\.delete",
      "@router\\.delete",
      "app\\.delete\\(",
      "router\\.delete\\(",
    },
    patch = {
      "@app\\.patch",
      "@router\\.patch",
      "app\\.patch\\(",
      "router\\.patch\\(",
    },
  },
}
