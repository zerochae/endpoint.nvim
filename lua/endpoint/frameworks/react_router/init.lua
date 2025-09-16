-- React Router Framework Module
local framework = require "endpoint.framework"

---@type endpoint.framework_base
return framework:new("react_router"):setup {
  file_extensions = { "*.js", "*.jsx", "*.ts", "*.tsx" },
  exclude_patterns = { "**/node_modules/**", "**/build/**", "**/dist/**" },
  detection = {
    files = { "package.json" },
    dependencies = { "react-router", "react-router-dom" },
    manifest_files = { "package.json" },
  },
  type = "pattern",
  patterns = {
    -- React Router doesn't use HTTP methods - all patterns are the same
    ROUTE = { "Route", "path:" }, -- <Route> components and createBrowserRouter format
  },
  parser = require "endpoint.frameworks.react_router.parser",
}