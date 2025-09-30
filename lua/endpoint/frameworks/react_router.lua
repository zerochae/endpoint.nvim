local Framework = require "endpoint.core.Framework"
local class = require "endpoint.lib.middleclass"
local ReactRouterParser = require "endpoint.parser.react_router_parser"

---@class endpoint.ReactRouterFramework
local ReactRouterFramework = class('ReactRouterFramework', Framework)

---Creates a new ReactRouterFramework instance
function ReactRouterFramework:initialize()
  Framework.initialize(self, {
    name = "react_router",
    config = {
      file_extensions = { "*.tsx", "*.jsx", "*.ts", "*.js" },
      exclude_patterns = { "**/node_modules", "**/dist", "**/build" },
      patterns = {
        ROUTE = { "Route", "path:" }, -- React Router doesn't use HTTP methods
      },
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
    },
  })
end

return ReactRouterFramework
