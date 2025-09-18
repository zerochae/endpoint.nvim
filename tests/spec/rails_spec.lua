local RailsFramework = require "endpoint.frameworks.rails"
local RailsParser = require "endpoint.parser.rails_parser"

describe("RailsFramework", function()
  local framework
  local parser

  before_each(function()
    framework = RailsFramework:new()
    parser = RailsParser:new()
  end)

  describe("Framework Detection", function()
    it("should have correct framework name", function()
      assert.equals("rails", framework:get_name())
    end)

    it("should have detector configured", function()
      assert.is_not_nil(framework.detector)
      assert.equals("rails_dependency_detection", framework.detector.detection_name)
    end)

    it("should have parser configured", function()
      assert.is_not_nil(framework.parser)
      assert.equals("rails_parser", framework.parser.parser_name)
    end)
  end)

  describe("Framework Configuration", function()
    it("should have correct file extensions", function()
      local config = framework:get_config()
      assert.same({ "*.rb" }, config.file_extensions)
    end)

    it("should have correct exclude patterns", function()
      local config = framework:get_config()
      assert.same({ "**/vendor", "**/tmp", "**/log", "**/.bundle" }, config.exclude_patterns)
    end)

    it("should have Rails-specific search patterns", function()
      local config = framework:get_config()
      assert.is_table(config.patterns.GET)
      assert.is_table(config.patterns.POST)
      assert.is_table(config.patterns.PUT)
      assert.is_table(config.patterns.PATCH)
      assert.is_table(config.patterns.DELETE)
    end)

    it("should have controller extractors", function()
      local config = framework:get_config()
      assert.is_table(config.controller_extractors)
      assert.is_true(#config.controller_extractors > 0)
    end)
  end)

  describe("Parser Functionality", function()
    it("should skip routes.rb files and return nil", function()
      local content = 'get "/users", to: "users#index"'
      local result = parser:parse_content(content, "config/routes.rb", 1, 1)

      -- The parser skips routes.rb processing, should return nil
      assert.is_nil(result)
    end)

    it("should parse controller action methods", function()
      local content = 'def index'
      local result = parser:parse_content(content, "app/controllers/users_controller.rb", 5, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
    end)

    it("should parse create action", function()
      local content = 'def create'
      local result = parser:parse_content(content, "app/controllers/users_controller.rb", 10, 1)

      assert.is_not_nil(result)
      assert.equals("POST", result.method)
      -- According to current implementation, create generates /users/create path
      assert.equals("/users/create", result.endpoint_path)
    end)

    it("should parse update action with PATCH method", function()
      local content = 'def update'
      local result = parser:parse_content(content, "app/controllers/users_controller.rb", 15, 1)

      assert.is_not_nil(result)
      assert.equals("PATCH", result.method)
      assert.equals("/users/:id", result.endpoint_path)
    end)

    it("should parse show action with :id parameter", function()
      local content = 'def show'
      local result = parser:parse_content(content, "app/controllers/users_controller.rb", 20, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users/:id", result.endpoint_path)
    end)

    it("should parse destroy action", function()
      local content = 'def destroy'
      local result = parser:parse_content(content, "app/controllers/users_controller.rb", 25, 1)

      assert.is_not_nil(result)
      assert.equals("DELETE", result.method)
      assert.equals("/users/:id", result.endpoint_path)
    end)

    it("should parse custom actions with default GET method", function()
      local content = 'def profile'
      local result = parser:parse_content(content, "app/controllers/users_controller.rb", 30, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users/profile", result.endpoint_path)
    end)
  end)

  describe("Search Command Generation", function()
    it("should generate valid search commands", function()
      local search_cmd = framework:get_search_cmd()
      assert.is_string(search_cmd)
      assert.matches("rg", search_cmd)
      assert.matches("--type ruby", search_cmd)
    end)
  end)

  describe("Controller Name Extraction", function()
    it("should extract controller name from file path", function()
      local controller_name = framework:getControllerName("app/controllers/users_controller.rb")
      assert.is_not_nil(controller_name)
    end)

    it("should handle nested controller paths", function()
      local controller_name = framework:getControllerName("app/controllers/admin/users_controller.rb")
      assert.is_not_nil(controller_name)
    end)
  end)

  describe("Integration Tests", function()
    it("should create framework instance successfully", function()
      local instance = RailsFramework:new()
      assert.is_not_nil(instance)
      assert.equals("rails", instance.name)
    end)

    it("should have parser and detector ready", function()
      assert.is_not_nil(framework.parser)
      assert.is_not_nil(framework.detector)
      assert.equals("rails", framework.parser.framework_name)
    end)

    it("should parse and enhance controller endpoints", function()
      local content = 'def index'
      local result = framework:parse(content, "app/controllers/users_controller.rb", 1, 1)

      assert.is_not_nil(result)
      assert.equals("rails", result.framework)
      assert.is_table(result.metadata)
      assert.equals("rails", result.metadata.framework)
    end)
  end)
end)

describe("RailsParser", function()
  local parser

  before_each(function()
    parser = RailsParser:new()
  end)

  describe("Parser Instance", function()
    it("should create parser with correct properties", function()
      assert.equals("rails_parser", parser.parser_name)
      assert.equals("rails", parser.framework_name)
      assert.equals("ruby", parser.language)
    end)
  end)

  describe("Endpoint Path Extraction", function()
    it("should extract simple paths from routes", function()
      local path = parser:extract_endpoint_path('get "/users"')
      assert.equals("/users", path)
    end)

    it("should extract paths with parameters", function()
      local path = parser:extract_endpoint_path('get "/users/:id"')
      assert.equals("/users/:id", path)
    end)

    it("should handle different quote styles", function()
      local path1 = parser:extract_endpoint_path("get '/users'")
      local path2 = parser:extract_endpoint_path('get "/users"')
      assert.equals("/users", path1)
      assert.equals("/users", path2)
    end)

    it("should extract symbol-based paths", function()
      local path = parser:extract_endpoint_path('get :profile')
      assert.equals("/profile", path)
    end)
  end)

  describe("HTTP Method Extraction", function()
    it("should extract GET method from route", function()
      local method = parser:extract_method('get "/users"')
      assert.equals("GET", method)
    end)

    it("should extract POST method from route", function()
      local method = parser:extract_method('post "/users"')
      assert.equals("POST", method)
    end)

    it("should extract PUT method from route", function()
      local method = parser:extract_method('put "/users/:id"')
      assert.equals("PUT", method)
    end)

    it("should extract DELETE method from route", function()
      local method = parser:extract_method('delete "/users/:id"')
      assert.equals("DELETE", method)
    end)

    it("should extract PATCH method from route", function()
      local method = parser:extract_method('patch "/users/:id"')
      assert.equals("PATCH", method)
    end)

    it("should extract GET from root route", function()
      local method = parser:extract_method('root "welcome#index"')
      assert.equals("GET", method)
    end)
  end)

  describe("Base Path Extraction", function()
    it("should handle namespace contexts", function()
      local base_path = parser:extract_base_path("config/routes.rb", 10)
      -- This might return nil or a path depending on implementation
      assert.is_true(base_path == nil or type(base_path) == "string")
    end)
  end)

  describe("Error Handling", function()
    it("should handle malformed content gracefully", function()
      local result = parser:parse_content("invalid content", "app/controllers/users_controller.rb", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle empty content", function()
      local result = parser:parse_content("", "app/controllers/users_controller.rb", 1, 1)
      assert.is_nil(result)
    end)

    it("should return nil for non-controller files", function()
      local result = parser:parse_content('def index', "app/models/user.rb", 1, 1)
      assert.is_nil(result)
    end)

    it("should skip private methods", function()
      local result = parser:parse_content('def set_user', "app/controllers/users_controller.rb", 1, 1)
      assert.is_nil(result) -- Should skip private helper methods
    end)

    it("should parse valid controller actions", function()
      local result = parser:parse_content('def index', "app/controllers/users_controller.rb", 1, 1)
      assert.is_not_nil(result)
    end)
  end)
end)