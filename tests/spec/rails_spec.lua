describe("Rails framework", function()
  local rails = require "endpoint.frameworks.rails"

  describe("framework detection", function()
    it("should detect Rails project", function()
      local fixture_path = "tests/fixtures/rails"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        local detected = rails.detect()
        assert.is_true(detected)

        vim.fn.chdir(original_cwd)
      else
        pending "Rails fixture directory not found"
      end
    end)

    it("should not detect Rails in non-Rails directory", function()
      local temp_dir = "/tmp/non-rails-test"
      vim.fn.mkdir(temp_dir, "p")

      local original_cwd = vim.fn.getcwd()
      vim.fn.chdir(temp_dir)

      local detected = rails.detect()
      assert.is_false(detected)

      vim.fn.chdir(original_cwd)
      vim.fn.delete(temp_dir, "rf")
    end)
  end)

  describe("search command generation", function()
    it("should generate correct search command for GET method", function()
      local cmd = rails.get_search_cmd("GET")
      assert.is_string(cmd)
      assert.is_not_nil(cmd:match("rg"))
      assert.is_not_nil(cmd:match("def index"))
      assert.is_not_nil(cmd:match("def show"))
      assert.is_not_nil(cmd:match("get "))
    end)

    it("should generate correct search command for POST method", function()
      local cmd = rails.get_search_cmd("POST")
      assert.is_string(cmd)
      assert.is_not_nil(cmd:match("def create"))
      assert.is_not_nil(cmd:match("post "))
    end)

    it("should generate correct search command for ALL methods", function()
      local cmd = rails.get_search_cmd("ALL")
      assert.is_string(cmd)
      assert.is_not_nil(cmd:match("def index"))
      assert.is_not_nil(cmd:match("def create"))
      assert.is_not_nil(cmd:match("def update"))
      assert.is_not_nil(cmd:match("get "))
      assert.is_not_nil(cmd:match("post "))
    end)

    it("should include proper file globs", function()
      local cmd = rails.get_search_cmd("GET")
      assert.is_not_nil(cmd:match("%-%-glob '%*%*/%*%.rb'"))
      assert.is_not_nil(cmd:match("%-%-glob '!%*%*/vendor/%*%*'"))
      assert.is_not_nil(cmd:match("%-%-glob '!%*%*/log/%*%*'"))
      assert.is_not_nil(cmd:match("%-%-glob '!%*%*/tmp/%*%*'"))
    end)
  end)

  describe("line parsing", function()
    it("should parse controller action lines", function()
      local line = "app/controllers/users_controller.rb:5:3:  def index"
      local result = rails.parse_line(line, "GET")
      
      assert.is_not_nil(result)
      assert.equals("app/controllers/users_controller.rb", result.file_path)
      assert.equals(5, result.line_number)
      assert.equals(3, result.column)
      assert.equals("GET", result.method)
      assert.equals("/users", result.endpoint_path)
      assert.equals("GET /users", result.display_value)
    end)

    it("should parse API controller action lines", function()
      local line = "app/controllers/api/v1/users_controller.rb:10:3:  def show"
      local result = rails.parse_line(line, "GET")
      
      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/api/v1/users/:id", result.endpoint_path)
    end)

    it("should parse routes.rb lines", function()
      local line = "config/routes.rb:5:3:  get '/health', to: 'health#check'"
      local result = rails.parse_line(line, "ALL")
      
      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/health", result.endpoint_path)
    end)

    it("should skip non-controller/routes files", function()
      local line = "app/models/user.rb:5:3:  def index"
      local result = rails.parse_line(line, "GET")
      
      assert.is_nil(result)
    end)

    it("should filter by method when specified", function()
      local line = "app/controllers/users_controller.rb:5:3:  def create"
      local result = rails.parse_line(line, "GET")
      
      assert.is_nil(result)
    end)
  end)

  describe("endpoint information extraction", function()
    describe("controller actions", function()
      it("should extract standard CRUD actions", function()
        local test_cases = {
          { "def index", "GET", "users", "/users" },
          { "def show", "GET", "users", "/users/:id" },
          { "def new", "GET", "users", "/users/new" },
          { "def edit", "GET", "users", "/users/:id/edit" },
          { "def create", "POST", "users", "/users" },
          { "def update", "PATCH", "users", "/users/:id" },
          { "def destroy", "DELETE", "users", "/users/:id" }
        }

        for _, case in ipairs(test_cases) do
          local content, expected_method, controller, expected_path = unpack(case)
          local file_path = "app/controllers/" .. controller .. "_controller.rb"
          local result = rails.extract_controller_action(content, file_path, 1)
          
          assert.is_not_nil(result, "Failed for: " .. content)
          assert.equals(expected_method, result.method, "Method mismatch for: " .. content)
          assert.equals(expected_path, result.path, "Path mismatch for: " .. content)
        end
      end)

      it("should handle custom actions", function()
        local content = "def profile"
        local file_path = "app/controllers/users_controller.rb"
        local result = rails.extract_controller_action(content, file_path, 1)
        
        assert.is_not_nil(result)
        assert.equals("GET", result.method)
        assert.equals("/users/:id/profile", result.path)
      end)

      it("should handle collection actions", function()
        local content = "def search"
        local file_path = "app/controllers/users_controller.rb"
        local result = rails.extract_controller_action(content, file_path, 1)
        
        assert.is_not_nil(result)
        assert.equals("GET", result.method)
        assert.equals("/users/search", result.path)
      end)
    end)

    describe("route definitions", function()
      it("should extract explicit routes", function()
        local test_cases = {
          { "get '/health', to: 'health#check'", "GET", "/health" },
          { "post '/api/login', to: 'sessions#create'", "POST", "/api/login" },
          { "delete '/logout'", "DELETE", "/logout" }
        }

        for _, case in ipairs(test_cases) do
          local content, expected_method, expected_path = unpack(case)
          local result = rails.extract_route_definition(content, "config/routes.rb", 1)
          
          assert.is_not_nil(result, "Failed for: " .. content)
          assert.equals(expected_method, result.method, "Method mismatch for: " .. content)
          assert.equals(expected_path, result.path, "Path mismatch for: " .. content)
        end
      end)

      it("should skip resource routes", function()
        local content = "resources :users"
        local result = rails.extract_route_definition(content, "config/routes.rb", 1)
        
        -- Resources declarations should be skipped
        assert.is_nil(result)
      end)

      it("should skip namespace routes", function()
        local content = "namespace :api"
        local result = rails.extract_route_definition(content, "config/routes.rb", 1)
        
        -- Namespace declarations should be skipped
        assert.is_nil(result)
      end)
    end)
  end)

  describe("controller name extraction", function()
    it("should extract simple controller names", function()
      local file_path = "app/controllers/users_controller.rb"
      local name = rails.extract_controller_name(file_path)
      assert.equals("users", name)
    end)

    it("should handle nested controllers", function()
      local file_path = "app/controllers/admin/users_controller.rb"
      local name = rails.extract_controller_name(file_path)
      assert.equals("admin/users", name)
    end)

    it("should handle API controllers", function()
      local file_path = "app/controllers/api/v1/users_controller.rb"
      local name = rails.extract_controller_name(file_path)
      assert.equals("api/v1/users", name)
    end)
  end)

  describe("action path generation", function()
    it("should generate correct paths for standard actions", function()
      local test_cases = {
        { "users", "index", "/users" },
        { "users", "show", "/users/:id" },
        { "users", "new", "/users/new" },
        { "users", "edit", "/users/:id/edit" },
        { "users", "create", "/users" },
        { "users", "update", "/users/:id" },
        { "users", "destroy", "/users/:id" }
      }

      for _, case in ipairs(test_cases) do
        local controller, action, expected_path = unpack(case)
        local file_path = "app/controllers/" .. controller .. "_controller.rb"
        local path = rails.generate_action_path(controller, action, file_path)
        
        assert.equals(expected_path, path, "Path mismatch for " .. controller .. "#" .. action)
      end
    end)

    it("should handle API controllers correctly", function()
      local controller = "api/v1/users"
      local file_path = "app/controllers/api/v1/users_controller.rb"
      
      local path = rails.generate_action_path(controller, "index", file_path)
      assert.equals("/api/v1/users", path)
      
      path = rails.generate_action_path(controller, "show", file_path)
      assert.equals("/api/v1/users/:id", path)
    end)

    it("should handle nested controllers", function()
      local controller = "admin/users"
      local file_path = "app/controllers/admin/users_controller.rb"
      
      local path = rails.generate_action_path(controller, "index", file_path)
      assert.equals("/admin/users", path)
    end)
  end)

  describe("action suffix detection", function()
    it("should identify member actions", function()
      local member_actions = { "profile", "update_status", "like", "unlike", "share" }
      
      for _, action in ipairs(member_actions) do
        local suffix = rails.get_action_suffix(action)
        assert.equals("/:id/" .. action, suffix, "Member action suffix mismatch for: " .. action)
      end
    end)

    it("should identify collection actions", function()
      local collection_actions = { "search", "export", "import", "bulk_update" }
      
      for _, action in ipairs(collection_actions) do
        local suffix = rails.get_action_suffix(action)
        assert.equals("/" .. action, suffix, "Collection action suffix mismatch for: " .. action)
      end
    end)
  end)
end)