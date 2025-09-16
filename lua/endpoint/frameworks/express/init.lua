-- Express.js Framework Module
local framework = require "endpoint.framework"

---@type endpoint.framework_base
return framework:new("express"):setup {
  file_extensions = { "*.js", "*.ts" },
  exclude_patterns = { "**/node_modules/**", "**/dist/**" },
  detection = {
    files = { "package.json", "app.js", "server.js", "index.js" },
    dependencies = { "express" },
    manifest_files = { "package.json" },
  },
  type = "pattern",
  patterns = {
    GET = { "app\\.get\\(", "router\\.get\\(", "\\bget\\(" },
    POST = { "app\\.post\\(", "router\\.post\\(", "\\bpost\\(" },
    PUT = { "app\\.put\\(", "router\\.put\\(", "\\bput\\(" },
    DELETE = { "app\\.delete\\(", "router\\.delete\\(", "\\bdelete\\(", "\\bdel\\(" },
    PATCH = { "app\\.patch\\(", "router\\.patch\\(", "\\bpatch\\(" },
  },
  parser = require "endpoint.frameworks.express.parser",
}
