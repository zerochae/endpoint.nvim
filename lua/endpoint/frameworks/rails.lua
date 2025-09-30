local Framework = require "endpoint.core.Framework"
local class = require "endpoint.lib.middleclass"
local RailsParser = require "endpoint.parser.rails_parser"

---@class endpoint.RailsFramework
local RailsFramework = class('RailsFramework', Framework)

---Creates a new RailsFramework instance
function RailsFramework:initialize()
  Framework.initialize(self, {
    name = "rails",
    config = {
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
    },
  })
end

return RailsFramework
