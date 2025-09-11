describe(" Rails framework", function()
  local rails = require "endpoint.framework.registry.rails"

  describe("pattern matching", function()
    it("should detect GET routes with route definition", function()
      local patterns = rails:get_patterns "get"
      assert.is_not_nil(patterns)
      assert.is_true(#patterns > 0)
      assert.is_true(vim.tbl_contains(patterns, "get\\s+['\"]"))
    end)

    it("should detect POST routes with route definition", function()
      local patterns = rails:get_patterns "post"
      assert.is_not_nil(patterns)
      assert.is_true(#patterns > 0)
      assert.is_true(vim.tbl_contains(patterns, "post\\s+['\"]"))
    end)

    it("should detect GET routes with controller methods", function()
      local patterns = rails:get_patterns "get"
      assert.is_true(vim.tbl_contains(patterns, "def\\s+(show|index|new|edit)"))
    end)

    it("should detect resources routes", function()
      local patterns = rails:get_patterns "get"
      assert.is_true(vim.tbl_contains(patterns, "resources\\s+:"))
    end)

    it("should return empty for unknown methods", function()
      local patterns = rails:get_patterns "unknown"
      assert.are.same({}, patterns)
    end)
  end)

  describe("file type detection", function()
    it("should return Ruby file types", function()
      local file_types = rails:get_file_types()
      assert.is_true(vim.tbl_contains(file_types, "rb"))
    end)
  end)

  describe("path extraction with real files", function()
    it("should extract path from route definition", function()
      local content = "get '/users', to: 'users#index'"
      local endpoint_path = rails:extract_endpoint_path(content, "get")
      assert.are.equal("/users", endpoint_path)
    end)

    it("should extract path from resources", function()
      local content = "resources :users"
      local endpoint_path = rails:extract_endpoint_path(content, "get")
      assert.are.equal("/users", endpoint_path)
    end)

    it("should extract path from controller method - index", function()
      local content = "def index"
      local endpoint_path = rails:extract_endpoint_path(content, "get")
      assert.are.equal("", endpoint_path)
    end)

    it("should extract path from controller method - show", function()
      local content = "def show"
      local endpoint_path = rails:extract_endpoint_path(content, "get")
      assert.are.equal("/:id", endpoint_path)
    end)

    it("should extract path from controller method - create", function()
      local content = "def create"
      local endpoint_path = rails:extract_endpoint_path(content, "post")
      assert.are.equal("", endpoint_path)
    end)

    it("should extract path from controller method - custom action", function()
      local content = "def login"
      local endpoint_path = rails:extract_endpoint_path(content, "post")
      assert.are.equal("/login", endpoint_path)
    end)
  end)

  describe("base path extraction with real files", function()
    it("should extract base path from UsersController", function()
      local real_file = "tests/fixtures/rails/test/dummy/app/controllers/users_controller.rb"
      local base_path = rails:get_base_path(real_file, 20)
      assert.are.equal("/users", base_path)
    end)

    it("should extract base path from ProjectsController", function()
      local real_file = "tests/fixtures/rails/test/dummy/app/controllers/projects_controller.rb"
      local base_path = rails:get_base_path(real_file, 5)
      assert.are.equal("/projects", base_path)
    end)

    it("should handle namespaced controller", function()
      local real_file = "tests/fixtures/rails/test/dummy/app/controllers/users/avatar_controller.rb"
      if vim.fn.filereadable(real_file) == 1 then
        local base_path = rails:get_base_path(real_file, 5)
        assert.is_not_nil(base_path)
      end
    end)
  end)

  describe("path combination", function()
    it("should combine controller base path with endpoint path", function()
      local full_path = rails:combine_paths("/users", "/:id")
      assert.are.equal("/users/:id", full_path)
    end)

    it("should handle empty endpoint path", function()
      local full_path = rails:combine_paths("/users", "")
      assert.are.equal("/users", full_path)
    end)

    it("should handle empty base path", function()
      local full_path = rails:combine_paths("", "/login")
      assert.are.equal("/login", full_path)
    end)

    it("should handle both empty paths", function()
      local full_path = rails:combine_paths("", "")
      assert.are.equal("/", full_path)
    end)

    it("should normalize paths with trailing/leading slashes", function()
      local full_path = rails:combine_paths("users/", "/show")
      assert.are.equal("/users/show", full_path)
    end)
  end)

  describe("route file parsing", function()
    it("should parse routes.rb file", function()
      local real_file = "tests/fixtures/rails/test/dummy/config/routes.rb"
      if vim.fn.filereadable(real_file) == 1 then
        local routes = rails:parse_routes_file(real_file)
        assert.is_not_nil(routes)
        assert.is_true(#routes > 0)
        
        -- Check if we found the login route
        local login_route = nil
        for _, route in ipairs(routes) do
          if route.endpoint_path == "/users/login" and route.method == "POST" then
            login_route = route
            break
          end
        end
        assert.is_not_nil(login_route)
      end
    end)

    it("should parse resources correctly", function()
      local real_file = "tests/fixtures/rails/test/dummy/config/routes.rb"
      if vim.fn.filereadable(real_file) == 1 then
        local routes = rails:parse_routes_file(real_file)
        
        -- Check if we found users resources routes
        local users_index_route = nil
        local users_show_route = nil
        
        for _, route in ipairs(routes) do
          if route.endpoint_path == "/users" and route.method == "GET" then
            users_index_route = route
          elseif route.endpoint_path == "/users/:id" and route.method == "GET" then
            users_show_route = route
          end
        end
        
        assert.is_not_nil(users_index_route)
        assert.is_not_nil(users_show_route)
      end
    end)
  end)

  describe("grep command generation", function()
    it("should generate valid grep command for GET method", function()
      local cmd = rails:get_grep_cmd("get", {})
      assert.is_string(cmd)
      assert.is_true(cmd:match("rg") ~= nil)
      assert.is_true(cmd:match("--type rb") ~= nil)
    end)

    it("should include exclude patterns", function()
      local cmd = rails:get_grep_cmd("get", {})
      assert.is_true(cmd:match("--glob '!%*%*/tmp/%*%*'") ~= nil)
      assert.is_true(cmd:match("--glob '!%*%*/log/%*%*'") ~= nil)
    end)
  end)

  describe("line parsing", function()
    it("should parse ripgrep output line", function()
      local test_line = "app/controllers/users_controller.rb:24:3:  def login"
      local result = rails:parse_line(test_line, "post", {})
      
      assert.is_not_nil(result)
      assert.are.equal("app/controllers/users_controller.rb", result.file_path)
      assert.are.equal(24, result.line_number)
      assert.are.equal(3, result.column)
      assert.are.equal("POST", result.method)
      assert.is_string(result.endpoint_path)
    end)

    it("should handle route definition line", function()
      local test_line = "config/routes.rb:2:3:  post '/users/login', to: 'users#login'"
      local result = rails:parse_line(test_line, "post", {})
      
      assert.is_not_nil(result)
      assert.are.equal("config/routes.rb", result.file_path)
      assert.are.equal(2, result.line_number)
      assert.are.equal("/users/login", result.endpoint_path)
      assert.are.equal("POST", result.method)
    end)

    it("should handle resources line", function()
      local test_line = "config/routes.rb:4:3:  resources :users"
      local result = rails:parse_line(test_line, "get", {})
      
      assert.is_not_nil(result)
      assert.are.equal("config/routes.rb", result.file_path)
      assert.are.equal(4, result.line_number)
      assert.are.equal("/users", result.endpoint_path)
      assert.are.equal("GET", result.method)
    end)

    it("should return nil for invalid line format", function()
      local test_line = "invalid line format"
      local result = rails:parse_line(test_line, "get", {})
      assert.is_nil(result)
    end)
  end)
end)