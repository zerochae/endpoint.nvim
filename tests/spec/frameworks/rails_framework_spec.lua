local RailsFramework = require "endpoint.frameworks.rails"

describe("RailsFramework", function()
  local framework

  before_each(function()
    framework = RailsFramework:new()
  end)

  describe("Display Format Tests", function()
    it("should format explicit routes correctly", function()
      local content = 'get "/users", to: "users#index"'
      local result = framework:_process_explicit_route(content, "routes.rb", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
      assert.equals("GET[users#index] /users", result.display_value)
      assert.equals("users#index", result.metadata.controller_action)
    end)

    it("should format controller actions correctly", function()
      local content = "def index"
      local result = framework:_process_controller_action(content, "app/controllers/users_controller.rb", 5, 3)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
      assert.equals("GET[users#index] /users", result.display_value)
      assert.equals("users", result.metadata.controller_name)
      assert.equals("index", result.metadata.action_name)
    end)

    it("should handle routes without controller#action", function()
      local content = 'get "/health"'
      local result = framework:_process_explicit_route(content, "routes.rb", 1, 1)

      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/health", result.endpoint_path)
      assert.equals("GET /health", result.display_value) -- No controller#action format
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
        assert.is_nil(result)
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
        assert.is_not_nil(result)
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
        assert.is_not_nil(result)
        assert.equals(test_case.expected, result.method)
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

        assert.is_not_nil(result)
        assert.equals(mapping.method, result.method)
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

        assert.is_not_nil(result)
        assert.equals(test.expected, result.endpoint_path)
      end
    end)
  end)

  describe("Metadata Generation", function()
    it("should include framework metadata", function()
      local content = 'get "/users", to: "users#index"'
      local result = framework:_process_explicit_route(content, "routes.rb", 1, 1)

      assert.is_not_nil(result.metadata)
      assert.equals("rails", result.metadata.framework_version)
      assert.equals("ruby", result.metadata.language)
      assert.equals("explicit", result.metadata.route_type)
    end)

    it("should include Rails-specific tags", function()
      local content = "def index"
      local result = framework:_process_controller_action(content, "app/controllers/users_controller.rb", 1, 1)

      assert.is_not_nil(result.tags)
      assert.is_true(vim.tbl_contains(result.tags, "ruby"))
      assert.is_true(vim.tbl_contains(result.tags, "rails"))
      assert.is_true(vim.tbl_contains(result.tags, "controller_action"))
    end)
  end)
end)

