local Framework = require "endpoint.core.Framework"
local Detector = require "endpoint.core.Detector"
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
      GET = { "app\\.get\\(", "router\\.get\\(", "\\.get\\(" },
      POST = { "app\\.post\\(", "router\\.post\\(", "\\.post\\(" },
      PUT = { "app\\.put\\(", "router\\.put\\(", "\\.put\\(" },
      DELETE = { "app\\.delete\\(", "router\\.delete\\(", "\\.delete\\(" },
      PATCH = { "app\\.patch\\(", "router\\.patch\\(", "\\.patch\\(" },
    },
    search_options = { "--type", "js" },
    controller_patterns = {
      { pattern = "([^/]+)%.%w+$", transform = function(name) return name:gsub("Controller$", ""):gsub("Routes$", ""):gsub("Router$", "") end }
    },
  })
  setmetatable(express_framework_instance, self)
  return express_framework_instance
end

---Sets up detection and parsing for Express
function ExpressFramework:_initialize()
  -- Setup detector
  self.detector = Detector:new_dependency_detector(
    { "express", "Express" },
    { "package.json", "server.js", "app.js", "index.js" },
    "express_dependency_detection"
  )

  -- Setup Express-specific parser
  self.parser = ExpressParser:new()
end

return ExpressFramework

