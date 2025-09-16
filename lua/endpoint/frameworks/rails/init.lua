-- Rails Framework Module
local framework = require "endpoint.framework"

---@type endpoint.framework_base
return framework:new("rails"):setup {
  file_extensions = { "*.rb" },
  exclude_patterns = {
    "**/vendor/**",
    "**/log/**",
    "**/tmp/**",
    "**/coverage/**",
    "**/node_modules/**"
  },
  detection = {
    files = { "Gemfile", "config/routes.rb", "config/application.rb", "app/controllers" },
    dependencies = { "rails", "actionpack" },
    manifest_files = { "Gemfile", "Gemfile.lock" },
  },
  type = "structure",
  target_files = { "routes.rb", "*_controller.rb" },
  parser = require "endpoint.frameworks.rails.parser",
}