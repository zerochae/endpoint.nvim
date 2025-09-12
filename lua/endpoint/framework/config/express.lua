return {
  file_patterns = { "**/*.js", "**/*.ts" },
  exclude_patterns = { "**/node_modules/**", "**/dist/**" },
  detection_files = { "package.json" }, -- Will check for express deps
  patterns = {
    get = { "\\.get\\(", "router\\.get" },
    post = { "\\.post\\(", "router\\.post" },
    put = { "\\.put\\(", "router\\.put" },
    delete = { "\\.delete\\(", "router\\.delete" },
    patch = { "\\.patch\\(", "router\\.patch" },
    all = { "\\.get\\(", "\\.post\\(", "\\.put\\(", "\\.delete\\(", "\\.patch\\(", "router\\." },
  },
}
