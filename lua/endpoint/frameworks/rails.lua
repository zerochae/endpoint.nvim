local Framework = require "endpoint.core.Framework"
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
        "def\\s+profile",
        "def\\s+search",
        "def\\s+featured",
        "def\\s+on_sale",
      },
      POST = {
        "post\\s+",
        "resources\\s+",
        "resource\\s+",
        "def\\s+create",
        "def\\s+like",
        "def\\s+share",
      },
      PUT = { "put\\s+", "resources\\s+", "resource\\s+", "def\\s+update" },
      PATCH = {
        "patch\\s+",
        "resources\\s+",
        "resource\\s+",
        "def\\s+update",
        "def\\s+update_status",
      },
      DELETE = {
        "delete\\s+",
        "resources\\s+",
        "resource\\s+",
        "def\\s+destroy",
        "def\\s+unlike",
      },
    },
    comment_patterns = { "^#" },
    search_options = { "--type", "ruby", "-U", "--multiline-dotall" },
    controller_extractors = {
      { pattern = "controllers/(.*)_controller%.rb$" },
    },
    detector = {
      dependencies = { "rails", "actionpack", "railties" },
      manifest_files = { "Gemfile", "config/routes.rb", "config/application.rb", "app/controllers" },
      name = "rails_dependency_detection",
    },
    parser = RailsParser,
  })
  setmetatable(rails_framework_instance, self)
  return rails_framework_instance
end

return RailsFramework
