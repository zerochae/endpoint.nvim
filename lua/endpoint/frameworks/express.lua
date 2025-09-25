local Framework = require "endpoint.core.Framework"
local ExpressParser = require "endpoint.parser.express_parser"

---@class endpoint.ExpressFramework
local ExpressFramework = setmetatable({}, { __index = Framework })
ExpressFramework.__index = ExpressFramework

---Creates a new ExpressFramework instance
function ExpressFramework:new()
  local express_framework_instance = Framework.new(self, "express", {
    file_extensions = { "*.js", "*.ts", "*.mjs" },
    exclude_patterns = { "**/node_modules", "**/dist", "**/build" },
    patterns = {
      GET = { "app\\.get\\b", "router\\.get\\b", "^\\s*get\\s*[<(]", "^[^/]*app\\.get\\s*<", "^[^/]*router\\.get\\s*<" },
      POST = {
        "app\\.post\\b",
        "router\\.post\\b",
        "^\\s*post\\s*[<(]",
        "^[^/]*app\\.post\\s*<",
        "^[^/]*router\\.post\\s*<",
      },
      PUT = { "app\\.put\\b", "router\\.put\\b", "^\\s*put\\s*[<(]", "^[^/]*app\\.put\\s*<", "^[^/]*router\\.put\\s*<" },
      DELETE = {
        "app\\.delete\\b",
        "router\\.delete\\b",
        "^\\s*(delete|del)\\s*[<(]",
        "^[^/]*app\\.delete\\s*<",
        "^[^/]*router\\.delete\\s*<",
      },
      PATCH = {
        "app\\.patch\\b",
        "router\\.patch\\b",
        "^\\s*patch\\s*[<(]",
        "^[^/]*app\\.patch\\s*<",
        "^[^/]*router\\.patch\\s*<",
      },
    },
    comment_patterns = { "^//", "^/%*", "^%*" },
    search_options = { "--type", "js", "--type", "ts", "-U", "--multiline-dotall" },
    controller_extractors = {
      {
        pattern = "([^/]+)%.%w+$",
        transform = function(name)
          return name:gsub("Controller$", ""):gsub("Routes$", ""):gsub("Router$", "")
        end,
      },
    },
    detector = {
      dependencies = { "express", "Express" },
      manifest_files = { "package.json", "server.js", "app.js", "index.js" },
      name = "express_dependency_detection",
    },
    parser = ExpressParser,
  })
  setmetatable(express_framework_instance, self)
  return express_framework_instance
end

return ExpressFramework
