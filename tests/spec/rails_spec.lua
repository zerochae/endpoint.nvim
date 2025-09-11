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

  describe("path extraction", function()
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

    it("should extract path from controller method - custom action", function()
      local content = "def login"
      local endpoint_path = rails:extract_endpoint_path(content, "post")
      assert.are.equal("/login", endpoint_path)
    end)

    it("should extract path from comment documentation", function()
      local content = "# GET /api/health"
      local endpoint_path = rails:extract_endpoint_path(content, "get")
      assert.are.equal("/api/health", endpoint_path)
    end)

    it("should extract path from @route documentation", function()
      local content = "# @route GET /api/version"
      local endpoint_path = rails:extract_endpoint_path(content, "get")
      assert.are.equal("/api/version", endpoint_path)
    end)

    it("should extract path from @method documentation", function()
      local content = "# @method POST /api/refresh"
      local endpoint_path = rails:extract_endpoint_path(content, "post")
      assert.are.equal("/api/refresh", endpoint_path)
    end)

    it("should detect OAS Rails @summary patterns", function()
      local patterns = rails:get_patterns "get"
      assert.is_true(vim.tbl_contains(patterns, "@summary.*Get"))
      assert.is_true(vim.tbl_contains(patterns, "@summary.*Show"))
    end)

    it("should detect OAS Rails @request_body patterns", function()
      local patterns = rails:get_patterns "post"
      assert.is_true(vim.tbl_contains(patterns, "@request_body"))
      assert.is_true(vim.tbl_contains(patterns, "@summary.*Create"))
    end)
  end)

  describe("base path extraction with real files", function()
    it("should extract base path from UsersController", function()
      local real_file = "tests/fixtures/rails/app/controllers/users_controller.rb"
      if vim.fn.filereadable(real_file) == 1 then
        local base_path = rails:get_base_path(real_file, 1)
        assert.are.equal("/users", base_path)
      end
    end)

    it("should extract base path from PostsController", function()
      local real_file = "tests/fixtures/rails/app/controllers/posts_controller.rb"
      if vim.fn.filereadable(real_file) == 1 then
        local base_path = rails:get_base_path(real_file, 1)
        assert.are.equal("/posts", base_path)
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
    end)
  end)

  describe("line parsing", function()
    it("should parse ripgrep output line", function()
      local test_line = "app/controllers/users_controller.rb:5:3:  def login"
      local result = rails:parse_line(test_line, "post", {})
      
      assert.is_not_nil(result)
      assert.are.equal("app/controllers/users_controller.rb", result.file_path)
      assert.are.equal(5, result.line_number)
      assert.are.equal(3, result.column)
      assert.are.equal("POST", result.method)
    end)

    it("should return nil for invalid line format", function()
      local test_line = "invalid line format"
      local result = rails:parse_line(test_line, "get", {})
      assert.is_nil(result)
    end)
  end)
end)