local RailsFramework = require "endpoint.frameworks.rails"
local test_utils = require "tests.helpers.test_utils"

describe("RailsFramework", function()
  local framework
  local test_context
  local fixture_base_dir

  before_each(function()
    framework = RailsFramework:new()
    test_context = test_utils.create_test_context()
    fixture_base_dir = test_utils.get_fixture_path "rails"
  end)

  after_each(function()
    if test_context then
      test_context:cleanup()
    end
  end)

  describe("Display Format Tests", function()
    it("should format explicit routes correctly", function()
      local content = 'get "/users", to: "users#index"'
      local result = framework:_process_explicit_route(content, "routes.rb", 1, 1)

      local is_valid, error_msg = test_utils.validate_endpoint_structure(result, {
        method = "GET",
        path = "/users",
      })
      test_utils.assert_true(is_valid, error_msg or "Endpoint validation failed")
      test_utils.assert_equal("GET[users#index] /users", result.display_value, "Display value mismatch")
      test_utils.assert_equal("users#index", result.metadata.controller_action, "Controller action mismatch")
    end)

    it("should format controller actions correctly", function()
      local content = "def index"
      local result = framework:_process_controller_action(content, "app/controllers/users_controller.rb", 5, 3)

      local is_valid, error_msg = test_utils.validate_endpoint_structure(result, {
        method = "GET",
        path = "/users",
      })
      test_utils.assert_true(is_valid, error_msg or "Endpoint validation failed")
      test_utils.assert_equal("GET[users#index] /users", result.display_value, "Display value mismatch")
      test_utils.assert_equal("users", result.metadata.controller_name, "Controller name mismatch")
      test_utils.assert_equal("index", result.metadata.action_name, "Action name mismatch")
    end)

    it("should handle routes without controller#action", function()
      local content = 'get "/health"'
      local result = framework:_process_explicit_route(content, "routes.rb", 1, 1)

      local is_valid, error_msg = test_utils.validate_endpoint_structure(result, {
        method = "GET",
        path = "/health",
      })
      test_utils.assert_true(is_valid, error_msg or "Endpoint validation failed")
      test_utils.assert_equal("GET /health", result.display_value, "Display value mismatch") -- No controller#action format
    end)
  end)

  describe("Private Method Detection", function()
    it("should exclude private helper methods", function()
      local private_methods = {
        "def user_params",
        "def set_user",
        "def authenticate_user",
        "def current_user",
        "def redirect_to_login",
      }

      for _, method_content in ipairs(private_methods) do
        local result = framework:_process_controller_action(method_content, "app/controllers/users_controller.rb", 1, 1)
        test_utils.assert_nil(result, "Expected nil result for private method")
      end
    end)

    it("should include valid controller actions", function()
      local valid_actions = {
        "def index",
        "def show",
        "def create",
        "def update",
        "def destroy",
        "def profile",
        "def search",
      }

      for _, action_content in ipairs(valid_actions) do
        local result = framework:_process_controller_action(action_content, "app/controllers/users_controller.rb", 1, 1)
        test_utils.assert_not_nil(result, "Expected non-nil result for valid action")
      end
    end)
  end)

  describe("HTTP Method Detection", function()
    it("should detect HTTP methods correctly", function()
      local test_cases = {
        { content = 'get "/users"', expected = "GET" },
        { content = 'post "/users"', expected = "POST" },
        { content = 'put "/users/:id"', expected = "PUT" },
        { content = 'patch "/users/:id"', expected = "PATCH" },
        { content = 'delete "/users/:id"', expected = "DELETE" },
      }

      for _, test_case in ipairs(test_cases) do
        local result = framework:_process_explicit_route(test_case.content, "routes.rb", 1, 1)
        test_utils.assert_not_nil(result, "Expected non-nil result for valid action")
        test_utils.assert_equal(test_case.expected, result.method, "HTTP method mismatch")
      end
    end)
  end)

  describe("Action to HTTP Method Mapping", function()
    it("should map controller actions to correct HTTP methods", function()
      local action_mappings = {
        { action = "index", method = "GET" },
        { action = "show", method = "GET" },
        { action = "new", method = "GET" },
        { action = "edit", method = "GET" },
        { action = "create", method = "POST" },
        { action = "update", method = "PUT" },
        { action = "destroy", method = "DELETE" },
      }

      for _, mapping in ipairs(action_mappings) do
        local content = "def " .. mapping.action
        local result = framework:_process_controller_action(content, "app/controllers/users_controller.rb", 1, 1)

        test_utils.assert_not_nil(result, "Expected non-nil result for valid action")
        test_utils.assert_equal(mapping.method, result.method, "Action to HTTP method mapping mismatch")
      end
    end)
  end)

  describe("Path Generation", function()
    it("should generate correct paths for controller actions", function()
      local path_tests = {
        { controller = "users_controller.rb", action = "index", expected = "/users" },
        { controller = "users_controller.rb", action = "show", expected = "/users/:id" },
        { controller = "admin/users_controller.rb", action = "index", expected = "/admin/users" },
        { controller = "api/v1/users_controller.rb", action = "index", expected = "/api/v1/users" },
      }

      for _, test in ipairs(path_tests) do
        local content = "def " .. test.action
        local file_path = "app/controllers/" .. test.controller
        local result = framework:_process_controller_action(content, file_path, 1, 1)

        test_utils.assert_not_nil(result, "Expected non-nil result for valid action")
        test_utils.assert_equal(test.expected, result.endpoint_path, "Path generation mismatch")
      end
    end)
  end)

  describe("Metadata Generation", function()
    it("should include framework metadata", function()
      local content = 'get "/users", to: "users#index"'
      local result = framework:_process_explicit_route(content, "routes.rb", 1, 1)

      test_utils.assert_not_nil(result.metadata, "Expected metadata to be present")
      test_utils.assert_equal("rails", result.metadata.framework_version, "Framework version mismatch")
      test_utils.assert_equal("ruby", result.metadata.language, "Language mismatch")
      test_utils.assert_equal("explicit", result.metadata.route_type, "Route type mismatch")
    end)

    it("should include Rails-specific tags", function()
      local content = "def index"
      local result = framework:_process_controller_action(content, "app/controllers/users_controller.rb", 1, 1)

      test_utils.assert_not_nil(result.tags, "Expected tags to be present")
      test_utils.assert_true(vim.tbl_contains(result.tags, "ruby"), "Expected ruby tag")
      test_utils.assert_true(vim.tbl_contains(result.tags, "rails"), "Expected rails tag")
      test_utils.assert_true(vim.tbl_contains(result.tags, "controller_action"), "Expected controller_action tag")
    end)
  end)

  describe("Integration Tests with Real Fixtures", function()
    describe("Controller Integration", function()
      it("should parse real UsersController actions", function()
        local controller_file = fixture_base_dir .. "/app/controllers/users_controller.rb"

        -- Test index action
        local result = framework:_process_controller_action("def index", controller_file, 4, 3)
        local is_valid, error_msg = test_utils.validate_endpoint_structure(result, {
          method = "GET",
          path = "/users",
        })
        test_utils.assert_true(is_valid, error_msg or "UsersController#index validation failed")
        test_utils.assert_equal("users", result.metadata.controller_name, "Controller name mismatch")
        test_utils.assert_equal("index", result.metadata.action_name, "Action name mismatch")
      end)

      -- TODO: Re-enable when member action detection is consistent
      -- it("should parse custom actions like profile", function()
      --   local controller_file = fixture_base_dir .. "/app/controllers/users_controller.rb"

      --   local result = framework:_process_controller_action("def profile", controller_file, 41, 3)
      --   local is_valid, error_msg = test_utils.validate_endpoint_structure(result, {
      --     method = "GET",
      --     path = "/users/:id/profile"  -- Expected path for member action
      --   })
      --   test_utils.assert_true(is_valid, error_msg or "UsersController#profile validation failed")
      --   test_utils.assert_equal("profile", result.metadata.action_name, "Custom action name mismatch")
      -- end)

      it("should handle nested namespace controllers", function()
        local controller_file = fixture_base_dir .. "/app/controllers/api/v1/users_controller.rb"

        local result = framework:_process_controller_action("def index", controller_file, 4, 3)
        local is_valid, error_msg = test_utils.validate_endpoint_structure(result, {
          method = "GET",
          path = "/api/v1/users",
        })
        test_utils.assert_true(is_valid, error_msg or "API::V1::UsersController#index validation failed")
        test_utils.assert_equal(
          "users",
          result.metadata.controller_name,
          "Controller name should be the base name without namespace"
        )
      end)

      it("should exclude private methods from parsing", function()
        local controller_file = fixture_base_dir .. "/app/controllers/users_controller.rb"

        -- Test private method
        local result = framework:_process_controller_action("def set_user", controller_file, 56, 3)
        test_utils.assert_nil(result, "Private methods should be excluded")

        -- Test private param method
        result = framework:_process_controller_action("def user_params", controller_file, 60, 3)
        test_utils.assert_nil(result, "Private param methods should be excluded")
      end)
    end)
  end)
end)
