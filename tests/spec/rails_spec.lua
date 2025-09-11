describe(" Rails framework", function()
  local rails = require "endpoint.framework.registry.rails"

  describe("pattern matching", function()
    it("should detect GET routes with controller methods", function()
      local patterns = rails:get_patterns "get"
      assert.is_not_nil(patterns)
      assert.is_true(#patterns > 0)
      assert.is_true(vim.tbl_contains(patterns, "def\\s+(show|index|new|edit)"))
    end)

    it("should detect POST routes with controller methods", function()
      local patterns = rails:get_patterns "post"
      assert.is_not_nil(patterns)
      assert.is_true(#patterns > 0)
      assert.is_true(vim.tbl_contains(patterns, "def\\s+create"))
    end)

    it("should return empty for unknown methods", function()
      local patterns = rails:get_patterns "unknown"
      assert.are.same({}, patterns)
    end)
  end)

  describe("file type detection", function()
    it("should return Ruby file types", function()
      local file_types = rails:get_file_types()
      assert.is_true(vim.tbl_contains(file_types, "ruby"))
    end)
  end)

  describe("path extraction", function()

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
      assert.is_true(cmd:match("--type ruby") ~= nil)
    end)

    it("should prioritize controller methods over routes patterns", function()
      local cmd = rails:get_grep_cmd("get", {})
      -- Should use only the first pattern (controller methods)
      assert.is_true(cmd:match("def\\s%+%(show|index|new|edit%)") ~= nil)
      -- Should NOT include multiple -e flags (single pattern mode)
      local e_count = 0
      for _ in cmd:gmatch(" %-e ") do
        e_count = e_count + 1
      end
      assert.are.equal(0, e_count, "Should use single pattern without -e flags")
    end)

    it("should prioritize controller methods for PUT requests", function()
      local cmd = rails:get_grep_cmd("put", {})
      assert.is_true(cmd:match("def\\s%+update") ~= nil)
      assert.is_true(cmd:match(" %-e ") == nil, "Should use single pattern")
    end)

    it("should prioritize controller methods for DELETE requests", function()
      local cmd = rails:get_grep_cmd("delete", {})
      assert.is_true(cmd:match("def\\s%+destroy") ~= nil)
      assert.is_true(cmd:match(" %-e ") == nil, "Should use single pattern")
    end)

    it("should prioritize controller methods for PATCH requests", function()
      local cmd = rails:get_grep_cmd("patch", {})
      assert.is_true(cmd:match("def\\s%+update") ~= nil)
      assert.is_true(cmd:match(" %-e ") == nil, "Should use single pattern")
    end)

    it("should include exclude patterns", function()
      local cmd = rails:get_grep_cmd("get", {})
      assert.is_true(cmd:match("--glob '!%*%*/tmp/%*%*'") ~= nil)
    end)
  end)

  describe("display method", function()
    it("should return native Rails method name in native mode", function()
      local content = "def index"
      local display_method = rails:get_display_method(content, "get")
      assert.are.equal("index", display_method)
    end)

    it("should return HTTP method in restful mode", function()
      -- This would require mocking the config, for now just test the default
      local content = "def create"
      local display_method = rails:get_display_method(content, "post")
      assert.are.equal("create", display_method)  -- native is default
    end)

    it("should handle custom Rails methods", function()
      local content = "def login"
      local display_method = rails:get_display_method(content, "post")
      assert.are.equal("login", display_method)
    end)
  end)

  describe("line parsing", function()
    it("should parse ripgrep output line with native display mode", function()
      local test_line = "app/controllers/users_controller.rb:5:3:  def login"
      local result = rails:parse_line(test_line, "post")
      
      assert.is_not_nil(result)
      assert.are.equal("app/controllers/users_controller.rb", result.file_path)
      assert.are.equal(5, result.line_number)
      assert.are.equal(3, result.column)
      assert.are.equal("login", result.method)  -- native mode shows Rails method name
    end)

    it("should parse standard Rails controller methods", function()
      local test_line = "app/controllers/posts_controller.rb:10:5:  def show"
      local result = rails:parse_line(test_line, "get")
      
      assert.is_not_nil(result)
      assert.are.equal("show", result.method)
      -- endpoint_path will be "/:id" (from show method) - base path extraction happens separately
      assert.is_true(result.endpoint_path:find("/:id") ~= nil)
    end)

    it("should return nil for invalid line format", function()
      local test_line = "invalid line format"
      local result = rails:parse_line(test_line, "get")
      assert.is_nil(result)
    end)
  end)
end)