local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
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
      ROUTE = { "Route", "path:" },  -- React Router doesn't use HTTP methods
    },
    search_options = { "--case-sensitive", "--type", "js" },
  })
  setmetatable(react_router_framework_instance, self)
  return react_router_framework_instance
end

---Sets up detection and parsing for React Router
function ReactRouterFramework:_initialize()
  -- Setup detector
  self.detector = DependencyDetector:new(
    { "react-router", "react-router-dom", "@reach/router" },
    { "package.json", "tsconfig.json", "src/" },
    "react_router_dependency_detection"
  )

  -- Setup React Router-specific parser
  self.parser = ReactRouterParser:new()
end

---Detects if React Router is present in the current project
function ReactRouterFramework:detect()
  if not self.detector then
    self:_initialize()
  end
  if self.detector then
    return self.detector:is_target_detected()
  end
  return false
end

---Extract component name from React Router file path
function ReactRouterFramework:getControllerName(file_path)
  -- React Router: src/components/UserProfile.tsx → UserProfile
  local name = file_path:match "([^/]+)%.[jt]sx?$"
  if name then
    return name
  end
  return nil
end

return ReactRouterFramework