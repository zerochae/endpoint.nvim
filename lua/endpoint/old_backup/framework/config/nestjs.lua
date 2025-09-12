return {
  file_patterns = { "**/*.ts" },
  exclude_patterns = { "**/node_modules/**", "**/dist/**" },
  detection_files = { "package.json" }, -- Will check for @nestjs/* deps
  patterns = {
    get = { "@Get\\(" },
    post = { "@Post\\(" },
    put = { "@Put\\(" },
    delete = { "@Delete\\(" },
    patch = { "@Patch\\(" },
    all = { "@Get\\(", "@Post\\(", "@Put\\(", "@Delete\\(", "@Patch\\(" },
  },
}
