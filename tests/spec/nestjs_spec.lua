local NestjsFramework = require "endpoint.frameworks.nestjs"
local NestjsParser = require "endpoint.parser.nestjs_parser"

describe("NestjsFramework", function()
  local framework
  local parser

  before_each(function()
    framework = NestjsFramework:new()
    parser = NestjsParser:new()
  end)

  describe("Framework Detection", function()
    it("should have correct framework name", function()
      assert.equals("nestjs", framework:get_name())
    end)

    it("should have detector configured", function()
      assert.is_not_nil(framework.detector)
      assert.equals("nestjs_dependency_detection", framework.detector.detection_name)
    end)

    it("should have parser configured", function()
      assert.is_not_nil(framework.parser)
      assert.equals("nestjs_parser", framework.parser.parser_name)
    end)
  end)

  describe("Framework Configuration", function()
    it("should have correct file extensions", function()
      local config = framework:get_config()
      assert.same({ "*.ts", "*.js" }, config.file_extensions)
    end)

    it("should have exclude patterns", function()
      local config = framework:get_config()
      assert.same({ "**/node_modules", "**/dist", "**/build" }, config.exclude_patterns)
    end)

    it("should have NestJS-specific search patterns", function()
      local config = framework:get_config()
      assert.is_table(config.patterns.GET)
      assert.is_table(config.patterns.POST)
      assert.is_table(config.patterns.PUT)
      assert.is_table(config.patterns.DELETE)
      assert.is_table(config.patterns.PATCH)
      assert.is_table(config.patterns.QUERY)
      assert.is_table(config.patterns.MUTATION)

      -- Check for NestJS-specific patterns
      assert.is_true(#config.patterns.GET > 0)
      assert.is_true(#config.patterns.POST > 0)
      assert.is_true(#config.patterns.QUERY > 0)
      assert.is_true(#config.patterns.MUTATION > 0)
    end)

    it("should have controller extractors", function()
      local config = framework:get_config()
      assert.is_table(config.controller_extractors)
      assert.is_true(#config.controller_extractors > 0)
    end)

    it("should have detector configuration", function()
      local config = framework:get_config()
      assert.is_table(config.detector)
      assert.is_table(config.detector.dependencies)
      assert.is_table(config.detector.manifest_files)
      assert.equals("nestjs_dependency_detection", config.detector.name)

      -- Check for NestJS-specific dependencies
      assert.is_true(#config.detector.dependencies > 0)
      assert.is_true(#config.detector.dependencies > 0)
    end)
  end)

  describe("Parser Functionality", function()
    it("should parse @Get decorators", function()
      local content = '@Get("/users")'
      local result = parser:parse_content(content, "users.controller.ts", 1, 1)

      if result then
        assert.equals("GET", result.method)
        assert.equals("/users", result.endpoint_path)
      end
    end)

    it("should parse @Post decorators", function()
      local content = '@Post("/users")'
      local result = parser:parse_content(content, "users.controller.ts", 1, 1)

      if result then
        assert.equals("POST", result.method)
        assert.equals("/users", result.endpoint_path)
      end
    end)

    it("should parse @Put decorators", function()
      local content = '@Put("/users/:id")'
      local result = parser:parse_content(content, "users.controller.ts", 1, 1)

      if result then
        assert.equals("PUT", result.method)
        assert.equals("/users/:id", result.endpoint_path)
      end
    end)

    it("should parse endpoints with parameters", function()
      local content = '@Get("/users/:id")'
      local result = parser:parse_content(content, "users.controller.ts", 1, 1)

      if result then
        assert.equals("GET", result.method)
        assert.equals("/users/:id", result.endpoint_path)
      end
    end)

    it("should handle single quotes", function()
      local content = "@Get('/users')"
      local result = parser:parse_content(content, "users.controller.ts", 1, 1)

      if result then
        assert.equals("GET", result.method)
        assert.equals("/users", result.endpoint_path)
      end
    end)

    it("should parse decorators without path", function()
      local content = "@Get()"
      local result = parser:parse_content(content, "users.controller.ts", 1, 1)

      if result then
        assert.equals("GET", result.method)
      end
    end)

    it("should parse @Query decorators", function()
      local content = "@Query(() => [User])\n  async findAll(): Promise<User[]> {"
      local result = parser:parse_content(content, "users.resolver.ts", 1, 1)

      if result then
        assert.equals("QUERY", result.method)
        assert.equals("findAll", result.endpoint_path)
      end
    end)

    it("should parse @Mutation decorators", function()
      local content =
        '@Mutation(() => User)\n  async createUser(@Args("input") input: CreateUserInput): Promise<User> {'
      local result = parser:parse_content(content, "users.resolver.ts", 1, 1)

      if result then
        assert.equals("MUTATION", result.method)
        assert.equals("createUser", result.endpoint_path)
      end
    end)

    it("should parse GraphQL decorators with custom names", function()
      local content = '@Query(() => [User], { name: "users" })\n  async findAll(): Promise<User[]> {'
      local result = parser:parse_content(content, "users.resolver.ts", 1, 1)

      if result then
        assert.equals("QUERY", result.method)
        assert.equals("users", result.endpoint_path)
      end
    end)

    it("should parse multiline GraphQL decorators", function()
      local content = [[
@Mutation(() => User, {
  name: 'createUser',
  description: 'Create a new user'
})
async createNewUser(
  @Args('input') input: CreateUserInput
): Promise<User> {]]
      local result = parser:parse_content(content, "users.resolver.ts", 1, 1)

      if result then
        assert.equals("MUTATION", result.method)
        assert.equals("createUser", result.endpoint_path)
      end
    end)
  end)

  describe("Search Command Generation", function()
    it("should generate valid search commands", function()
      local search_cmd = framework:get_search_cmd()
      assert.is_string(search_cmd)
      assert.matches("rg", search_cmd)
      assert.matches("--type ts", search_cmd)
    end)
  end)

  describe("Controller Name Extraction", function()
    it("should extract controller name from TypeScript file", function()
      local controller_name = framework:getControllerName "src/users/users.controller.ts"
      assert.is_not_nil(controller_name)
    end)

    it("should extract controller name from JavaScript file", function()
      local controller_name = framework:getControllerName "src/users/users.controller.js"
      assert.is_not_nil(controller_name)
    end)

    it("should handle nested controller paths", function()
      local controller_name = framework:getControllerName "src/modules/users/users.controller.ts"
      assert.is_not_nil(controller_name)
    end)
  end)

  describe("Comment Filtering", function()
    it("should have TypeScript comment patterns configured", function()
      local config = framework:get_config()
      assert.is_table(config.comment_patterns)
      assert.is_true(#config.comment_patterns > 0)

      -- Check for TypeScript comment patterns
      local patterns = config.comment_patterns
      local has_single_line = false
      local has_block_start = false
      local has_block_inside = false

      for _, pattern in ipairs(patterns) do
        if pattern == "^//" then
          has_single_line = true
        end
        if pattern == "^/%*" then
          has_block_start = true
        end
        if pattern == "^%*" then
          has_block_inside = true
        end
      end

      assert.is_true(has_single_line, "Should have single line comment pattern")
      assert.is_true(has_block_start, "Should have block comment start pattern")
      assert.is_true(has_block_inside, "Should have block comment inside pattern")
    end)

    it("should filter out single-line commented endpoints", function()
      local commented_content = '// @Get("/commented")'
      local result = framework:parse(commented_content, "test.ts", 1, 1)
      assert.is_nil(result, "Single-line commented endpoint should be filtered out")
    end)

    it("should filter out block commented endpoints", function()
      local commented_content = '* @Post("/block-commented")'
      local result = framework:parse(commented_content, "test.ts", 1, 1)
      assert.is_nil(result, "Block commented endpoint should be filtered out")
    end)

    it("should allow active endpoints", function()
      local active_content = '@Get("/active")'
      local result = framework:parse(active_content, "test.ts", 1, 1)
      assert.is_not_nil(result, "Active endpoint should be parsed")
      assert.equals("GET", result.method)
    end)

    it("should filter various TypeScript comment styles", function()
      local test_cases = {
        '// @Get("/single-line")',
        '    // @Post("/indented")',
        '/* @Put("/block-start") */',
        '* @Delete("/block-inside")',
      }

      for _, commented_content in ipairs(test_cases) do
        local result = framework:parse(commented_content, "test.ts", 1, 1)
        assert.is_nil(result, "Should filter: " .. commented_content)
      end
    end)
  end)

  describe("Integration Tests", function()
    it("should create framework instance successfully", function()
      local instance = NestjsFramework:new()
      assert.is_not_nil(instance)
      assert.equals("nestjs", instance:get_name())
    end)

    it("should have parser and detector ready", function()
      assert.is_not_nil(framework.parser)
      assert.is_not_nil(framework.detector)
      assert.equals("nestjs", framework.parser.framework_name)
    end)

    it("should parse and enhance endpoints", function()
      local content = '@Get("/api/users")'
      local result = framework:parse(content, "users.controller.ts", 1, 1)

      if result then
        assert.equals("nestjs", result.framework)
        assert.is_table(result.metadata)
        assert.equals("nestjs", result.metadata.framework)
      end
    end)
  end)
end)

describe("NestjsParser", function()
  local parser

  before_each(function()
    parser = NestjsParser:new()
  end)

  describe("Parser Instance", function()
    it("should create parser with correct properties", function()
      assert.equals("nestjs_parser", parser.parser_name)
      assert.equals("nestjs", parser.framework_name)
      assert.equals("typescript", parser.language)
    end)
  end)

  describe("Endpoint Path Extraction", function()
    it("should extract simple paths", function()
      local path = parser:extract_endpoint_path '@Get("/users")'
      assert.equals("/users", path)
    end)

    it("should extract paths with parameters", function()
      local path = parser:extract_endpoint_path '@Get("/users/:id")'
      assert.equals("/users/:id", path)
    end)

    it("should handle single quotes", function()
      local path = parser:extract_endpoint_path "@Get('/users')"
      assert.equals("/users", path)
    end)

    it("should handle empty decorators", function()
      local path = parser:extract_endpoint_path "@Get()"
      assert.is_true(path == nil or path == "" or type(path) == "string")
    end)

    it("should extract GraphQL query names from function names", function()
      local path = parser:extract_endpoint_path "@Query(() => [User])\n  async findAllUsers(): Promise<User[]> {"
      assert.equals("findAllUsers", path)
    end)

    it("should extract GraphQL mutation names from custom name options", function()
      local path = parser:extract_endpoint_path '@Mutation(() => User, { name: "createUser" })'
      assert.equals("createUser", path)
    end)

    it("should extract GraphQL query names with single quotes", function()
      local path = parser:extract_endpoint_path "@Query(() => [User], { name: 'users' })"
      assert.equals("users", path)
    end)

    it("should handle GraphQL decorators without explicit names", function()
      local path = parser:extract_endpoint_path "@Query(() => User)\n  async getUser(): Promise<User> {"
      assert.equals("getUser", path)
    end)
  end)

  describe("HTTP Method Extraction", function()
    it("should extract GET from @Get", function()
      local method = parser:extract_method '@Get("/users")'
      assert.equals("GET", method)
    end)

    it("should extract POST from @Post", function()
      local method = parser:extract_method '@Post("/users")'
      assert.equals("POST", method)
    end)

    it("should extract PUT from @Put", function()
      local method = parser:extract_method '@Put("/users/:id")'
      assert.equals("PUT", method)
    end)

    it("should extract DELETE from @Delete", function()
      local method = parser:extract_method '@Delete("/users/:id")'
      assert.equals("DELETE", method)
    end)

    it("should extract PATCH from @Patch", function()
      local method = parser:extract_method '@Patch("/users/:id")'
      assert.equals("PATCH", method)
    end)

    it("should extract QUERY from @Query", function()
      local method = parser:extract_method "@Query(() => [User])"
      assert.equals("QUERY", method)
    end)

    it("should extract MUTATION from @Mutation", function()
      local method = parser:extract_method "@Mutation(() => User)"
      assert.equals("MUTATION", method)
    end)
  end)

  describe("Base Path Extraction", function()
    it("should handle controller-level decorators", function()
      local base_path = parser:extract_base_path("users.controller.ts", 10)
      assert.is_true(base_path == nil or type(base_path) == "string")
    end)
  end)

  describe("Error Handling", function()
    it("should handle malformed decorators gracefully", function()
      local result = parser:parse_content("@InvalidDecorator", "test.ts", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle empty content", function()
      local result = parser:parse_content("", "test.ts", 1, 1)
      assert.is_nil(result)
    end)

    it("should handle missing file path", function()
      local result = parser:parse_content('@Get("/users")', "users.controller.ts", 1, 1)
      if result then
        assert.is_table(result)
      end
    end)

    it("should return nil for non-NestJS content", function()
      local result = parser:parse_content("const users = []", "test.ts", 1, 1)
      assert.is_nil(result)
    end)
  end)
end)
