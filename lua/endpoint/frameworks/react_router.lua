local Framework = require "endpoint.core.Framework"
local ReactRouterParser = require "endpoint.parser.react_router_parser"

---@class endpoint.ReactRouterFramework
local ReactRouterFramework = setmetatable({}, { __index = Framework })
ReactRouterFramework.__index = ReactRouterFramework

---Creates a new ReactRouterFramework instance
function ReactRouterFramework:new()
  local react_router_framework_instance = Framework.new(self, "react_router", {
    file_extensions = { "*.tsx", "*.jsx", "*.ts", "*.js" },
    exclude_patterns = { "**/node_modules", "**/dist", "**/build" },
    patterns = {
      ROUTE = { "Route", "path:" }, -- React Router doesn't use HTTP methods
    },
    comment_patterns = { "^//", "^/%*", "^%*" },
    search_options = { "--case-sensitive", "--type", "js" },
    controller_extractors = {
      { pattern = "([^/]+)%.[jt]sx?$" },
    },
    detector = {
      dependencies = { "react-router", "react-router-dom", "@reach/router" },
      manifest_files = { "package.json", "tsconfig.json", "src/" },
      name = "react_router_dependency_detection",
    },
    parser = ReactRouterParser,
  })
  setmetatable(react_router_framework_instance, self)
  return react_router_framework_instance
end

return ReactRouterFramework
