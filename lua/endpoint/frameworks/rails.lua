local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
local RailsParser = require "endpoint.parser.rails_parser"

---@class endpoint.RailsFramework
local RailsFramework = setmetatable({}, { __index = Framework })
RailsFramework.__index = RailsFramework

---Creates a new RailsFramework instance
function RailsFramework:new()
  local rails_framework_instance = Framework.new(self, "rails", {
    file_extensions = { "*.rb" },
    exclude_patterns = { "**/vendor", "**/tmp", "**/log", "**/.bundle" },
    patterns = {
      GET = {
        "get\\s+",
        "resources\\s+",
        "resource\\s+",
        "namespace\\s+",
        "root\\s+",
        "def\\s+index",
        "def\\s+show",
        "def\\s+new",
        "def\\s+edit",
      },
      POST = { "post\\s+", "resources\\s+", "resource\\s+", "def\\s+create" },
      PUT = { "put\\s+", "resources\\s+", "resource\\s+", "def\\s+update" },
      PATCH = { "patch\\s+", "resources\\s+", "resource\\s+", "def\\s+update" },
      DELETE = { "delete\\s+", "resources\\s+", "resource\\s+", "def\\s+destroy" },
    },
    search_options = { "--type", "ruby" },
  })
  setmetatable(rails_framework_instance, self)
  return rails_framework_instance
end

---Sets up detection and parsing for Rails
function RailsFramework:_initialize()
  -- Setup detector
  self.detector = DependencyDetector:new(
    { "rails", "actionpack", "railties" },
    { "Gemfile", "config/routes.rb", "config/application.rb", "app/controllers" },
    "rails_dependency_detection"
  )

  -- Setup Rails-specific parser
  self.parser = RailsParser:new()
end

---Detects if Rails is present in the current project
function RailsFramework:detect()
  if not self.detector then
    self:_initialize()
  end
  if self.detector then
    return self.detector:is_target_detected()
  end
  return false
end

---Extract controller name from Rails file path
function RailsFramework:getControllerName(file_path)
  -- Rails: app/controllers/users_controller.rb → users
  if file_path:match "controllers/.*%.rb$" then
    return file_path:match "controllers/(.*)_controller%.rb$"
  end
  return nil
end

return RailsFramework
