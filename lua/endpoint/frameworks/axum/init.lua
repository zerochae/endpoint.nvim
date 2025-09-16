-- Axum Framework Module
local framework = require "endpoint.framework"

---@type endpoint.framework_base
return framework:new("axum"):setup {
  file_extensions = { "*.rs" },
  exclude_patterns = { "**/target/**" },
  detection = {
    files = { "src/main.rs" },
    dependencies = { "axum" },
    manifest_files = { "Cargo.toml" },
  },
  type = "pattern",
  patterns = {
    GET = { "%.route", "Router::new" },
    POST = { "%.route", "Router::new" },
    PUT = { "%.route", "Router::new" },
    DELETE = { "%.route", "Router::new" },
    PATCH = { "%.route", "Router::new" },
  },
  parser = require "endpoint.frameworks.axum.parser",
}