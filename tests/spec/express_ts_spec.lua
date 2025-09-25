local ExpressFramework = require "endpoint.frameworks.express"
local ExpressParser = require "endpoint.parser.express_parser"

describe("Express TypeScript Support", function()
  local framework
  local parser

  before_each(function()
    framework = ExpressFramework:new()
    parser = ExpressParser:new()
  end)

  describe("TypeScript Generic Pattern Detection", function()
    it("should detect app.get with TypeScript generics", function()
      local content = "app.get<{}, MessageResponse>('/', (req, res) => {"
      assert.is_true(parser:is_content_valid_for_parsing(content))
    end)

    it("should detect router.post with complex generics", function()
      local content = "router.post<{}, ApiResponse<User>, CreateUserRequest>('/users', (req, res) => {"
      assert.is_true(parser:is_content_valid_for_parsing(content))
    end)

    it("should detect destructured methods with generics", function()
      local content = "get<{}, MessageResponse>('/api', (req, res) => {"
      assert.is_true(parser:is_content_valid_for_parsing(content))
    end)

    it("should detect multiline generics", function()
      local content = [[app.get<
  { userId: string; postId: string },
  ApiResponse<{ user: User; post: any }>
>('/api/users/:userId/posts/:postId', (req, res) => {]]
      assert.is_true(parser:is_content_valid_for_parsing(content))
    end)

    it("should detect deeply nested generics", function()
      local content = "app.put<Record<string, Map<number, Set<User>>>, Promise<ApiResponse<User[]>>>('/complex', (req, res) => {"
      assert.is_true(parser:is_content_valid_for_parsing(content))
    end)
  end)

  describe("Method Extraction with TypeScript", function()
    it("should extract GET method from TypeScript generics", function()
      local content = "app.get<{}, MessageResponse>('/', (req, res) => {"
      local method = parser:extract_method(content)
      assert.equals("GET", method)
    end)

    it("should extract POST method from complex generics", function()
      local content = "router.post<{}, ApiResponse<User>, CreateUserRequest>('/users', (req, res) => {"
      local method = parser:extract_method(content)
      assert.equals("POST", method)
    end)

    it("should extract PUT method from multiline generics", function()
      local content = [[app.put<
  { id: string },
  ApiResponse<User>,
  UpdateUserRequest
>('/users/:id', (req, res) => {]]
      local method = parser:extract_method(content)
      assert.equals("PUT", method)
    end)

    it("should extract DELETE method from destructured pattern", function()
      local content = "delete<{ id: string }, MessageResponse>('/users/:id', (req, res) => {"
      local method = parser:extract_method(content)
      assert.equals("DELETE", method)
    end)

    it("should extract PATCH method from standard pattern", function()
      local content = "app.patch<{ id: string }, ApiResponse<Partial<User>>>('/users/:id', (req, res) => {"
      local method = parser:extract_method(content)
      assert.equals("PATCH", method)
    end)

    it("should handle del alias for DELETE", function()
      local content = "del<{ id: string }, MessageResponse>('/users/:id', (req, res) => {"
      local method = parser:extract_method(content)
      assert.equals("DELETE", method)
    end)
  end)

  describe("Path Extraction with TypeScript", function()
    it("should extract path from simple TypeScript route", function()
      local content = "app.get<{}, MessageResponse>('/', (req, res) => {"
      local path = parser:extract_endpoint_path(content, "app.ts", 1)
      assert.equals("/", path)
    end)

    it("should extract path from complex generics", function()
      local content = "router.post<{}, ApiResponse<User>, CreateUserRequest>('/api/users', (req, res) => {"
      local path = parser:extract_endpoint_path(content, "routes/users.ts", 1)
      assert.equals("/api/users", path)
    end)

    it("should extract path with parameters", function()
      local content = "app.put<{ id: string }, ApiResponse<User>>('/users/:id', (req, res) => {"
      local path = parser:extract_endpoint_path(content, "app.ts", 1)
      assert.equals("/users/:id", path)
    end)

    it("should extract path from multiline generics", function()
      local content = [[app.get<
  { userId: string; postId: string },
  ApiResponse<{ user: User; post: any }>
>('/api/v1/users/:userId/posts/:postId', (req, res) => {]]
      local path = parser:extract_endpoint_path(content, "app.ts", 1)
      assert.equals("/api/v1/users/:userId/posts/:postId", path)
    end)

    it("should extract path from destructured method", function()
      local content = "get<{}, ApiResponse<any[]>>('/api/search', (req, res) => {"
      local path = parser:extract_endpoint_path(content, "destructured.ts", 1)
      assert.equals("/api/search", path)
    end)
  end)

  describe("Route Type Detection", function()
    it("should detect app route type", function()
      local content = "app.get<{}, MessageResponse>('/', (req, res) => {"
      local route_type = parser:_detect_route_type(content)
      assert.equals("app_route", route_type)
    end)

    it("should detect router route type", function()
      local content = "router.post<{}, ApiResponse<User>>('/users', (req, res) => {"
      local route_type = parser:_detect_route_type(content)
      assert.equals("router_route", route_type)
    end)

    it("should detect destructured route type", function()
      local content = "get<{}, MessageResponse>('/api', (req, res) => {"
      local route_type = parser:_detect_route_type(content)
      assert.equals("destructured_route", route_type)
    end)
  end)

  describe("App Type Extraction", function()
    it("should extract app type from app routes", function()
      local content = "app.get<{}, MessageResponse>('/', (req, res) => {"
      local app_type = parser:_extract_app_type(content)
      assert.equals("app", app_type)
    end)

    it("should extract router type from router routes", function()
      local content = "router.post<{}, ApiResponse<User>>('/users', (req, res) => {"
      local app_type = parser:_extract_app_type(content)
      assert.equals("router", app_type)
    end)

    it("should extract destructured type from destructured routes", function()
      local content = "get<{}, MessageResponse>('/api', (req, res) => {"
      local app_type = parser:_extract_app_type(content)
      assert.equals("destructured_get", app_type)
    end)

    it("should handle destructured delete alias", function()
      local content = "del<{ id: string }, MessageResponse>('/users/:id', (req, res) => {"
      local app_type = parser:_extract_app_type(content)
      assert.equals("destructured_del", app_type)
    end)
  end)

  describe("Parsing Confidence", function()
    it("should have high confidence for standard TypeScript patterns", function()
      local content = "app.get<{}, MessageResponse>('/', (req, res) => {"
      local confidence = parser:get_parsing_confidence(content)
      assert.is_true(confidence >= 0.9)
    end)

    it("should have high confidence for router patterns", function()
      local content = "router.post<{}, ApiResponse<User>>('/users', (req, res) => {"
      local confidence = parser:get_parsing_confidence(content)
      assert.is_true(confidence >= 0.9)
    end)

    it("should have good confidence for destructured patterns", function()
      local content = "get<{}, MessageResponse>('/api', (req, res) => {"
      local confidence = parser:get_parsing_confidence(content)
      assert.is_true(confidence >= 0.85)
    end)

    it("should have low confidence for invalid content", function()
      local content = "console.log('not a route');"
      local confidence = parser:get_parsing_confidence(content)
      assert.equals(0.0, confidence)
    end)
  end)

  describe("Full Parsing with TypeScript", function()
    it("should parse complete TypeScript endpoint", function()
      local content = "app.get<{}, ApiResponse<User[]>>('/users', (_req, res) => {"
      local endpoint = framework:parse(content, "app.ts", 25, 1)

      assert.is_not_nil(endpoint)
      assert.equals("GET", endpoint.method)
      assert.equals("/users", endpoint.endpoint_path)
      assert.equals("express", endpoint.framework)
      assert.equals("app.ts", endpoint.file_path)
      assert.equals(25, endpoint.line_number)
    end)

    it("should parse router endpoint with complex generics", function()
      local content = "router.post<{}, ApiResponse<User>, CreateUserRequest>('/users', (req, res) => {"
      local endpoint = framework:parse(content, "routes/users.ts", 42, 1)

      assert.is_not_nil(endpoint)
      assert.equals("POST", endpoint.method)
      assert.equals("/users", endpoint.endpoint_path)
      assert.equals("express", endpoint.framework)
      assert.equals("routes/users.ts", endpoint.file_path)
      assert.equals(42, endpoint.line_number)
    end)

    it("should parse destructured endpoint", function()
      local content = "patch<{ id: string }, ApiResponse<User>>('/users/:id', (req, res) => {"
      local endpoint = framework:parse(content, "destructured.ts", 15, 1)

      assert.is_not_nil(endpoint)
      assert.equals("PATCH", endpoint.method)
      assert.equals("/users/:id", endpoint.endpoint_path)
      assert.equals("express", endpoint.framework)
      assert.equals("destructured.ts", endpoint.file_path)
      assert.equals(15, endpoint.line_number)
    end)

    it("should add proper metadata for TypeScript routes", function()
      local content = "app.get<{}, MessageResponse>('/', (req, res) => {"
      local endpoint = framework:parse(content, "app.ts", 1, 1)

      assert.is_not_nil(endpoint.metadata)
      assert.equals("app_route", endpoint.metadata.route_type)
      assert.equals("app", endpoint.metadata.app_type)
      assert.same({ "javascript", "express", "route" }, endpoint.tags)
    end)
  end)

  describe("Edge Cases and Complex Scenarios", function()
    it("should handle extremely nested generics", function()
      local content = "app.put<Record<string, Map<number, Set<Promise<Array<User>>>>>, Promise<ApiResponse<Record<string, Array<{ id: number; data: Map<string, any> }>>>>>('/extreme', (req, res) => {"
      assert.is_true(parser:is_content_valid_for_parsing(content))

      local method = parser:extract_method(content)
      assert.equals("PUT", method)

      local path = parser:extract_endpoint_path(content, "app.ts", 1)
      assert.equals("/extreme", path)
    end)

    it("should handle whitespace variations in generics", function()
      local content = "app.get < { id : string } , ApiResponse < User > > ( '/users/:id' , (req, res) => {"
      assert.is_true(parser:is_content_valid_for_parsing(content))

      local method = parser:extract_method(content)
      assert.equals("GET", method)
    end)

    it("should reject invalid patterns", function()
      local invalid_patterns = {
        "console.log('not a route');",
        "const app = express();",
        "import express from 'express';",
        "// app.get('/comment', () => {})",
        "function getUsers() { return []; }"
      }

      -- Test each pattern individually to identify the culprit
      for i, pattern in ipairs(invalid_patterns) do
        local result = parser:is_content_valid_for_parsing(pattern)
        print("Pattern " .. i .. ": '" .. pattern .. "' -> " .. tostring(result))
        assert.is_false(result, "Pattern " .. i .. " should not match: " .. pattern)
      end
    end)

    it("should handle mixed JavaScript and TypeScript patterns", function()
      -- JavaScript pattern (no generics)
      local js_content = "app.get('/', (req, res) => {"
      assert.is_true(parser:is_content_valid_for_parsing(js_content))

      local js_method = parser:extract_method(js_content)
      assert.equals("GET", js_method)

      -- TypeScript pattern (with generics)
      local ts_content = "app.get<{}, MessageResponse>('/', (req, res) => {"
      assert.is_true(parser:is_content_valid_for_parsing(ts_content))

      local ts_method = parser:extract_method(ts_content)
      assert.equals("GET", ts_method)
    end)
  end)

  describe("Multiline Generic Support", function()
    it("should parse simple multiline generic", function()
      local content = [[app.get<
  FooType,
  BarType
>('/complex-nested', (req, res) => {]]

      local endpoint = framework:parse(content, "test.ts", 167, 1)
      assert.is_not_nil(endpoint)
      assert.equals("GET", endpoint.method)
      assert.equals("/complex-nested", endpoint.endpoint_path)
      assert.equals("GET /complex-nested", endpoint.display_value)
    end)

    it("should parse complex multiline generic with multiple types", function()
      local content = [[app.get<
  { userId: string; postId: string },
  ApiResponse<{ user: User; post: any }>,
  {},
  QueryParams
>('/api/v1/users/:userId/posts/:postId', (req, res) => {]]

      local endpoint = framework:parse(content, "test.ts", 138, 1)
      assert.is_not_nil(endpoint)
      assert.equals("GET", endpoint.method)
      assert.equals("/api/v1/users/:userId/posts/:postId", endpoint.endpoint_path)
    end)

    it("should parse extreme nested generics", function()
      local content = [[app.put<
  Record<string, Map<number, Set<Promise<Array<User>>>>>,
  Promise<ApiResponse<Record<string, Array<{ id: number; data: Map<string, any> }>>>>
>('/extreme-nesting', (req, res) => {]]

      local endpoint = framework:parse(content, "test.ts", 182, 1)
      assert.is_not_nil(endpoint)
      assert.equals("PUT", endpoint.method)
      assert.equals("/extreme-nesting", endpoint.endpoint_path)
    end)

    it("should parse multiline router generics", function()
      local content = [[router.get<
  { id: string; action: string },
  ApiResponse<{ user: User; action: string }>,
  {},
  { details?: boolean }
>('/:id/:action', (req, res) => {]]

      local endpoint = framework:parse(content, "test.ts", 100, 1)
      assert.is_not_nil(endpoint)
      assert.equals("GET", endpoint.method)
      assert.equals("/:id/:action", endpoint.endpoint_path)
    end)

    it("should validate multiline generic content", function()
      -- First line of multiline generic
      local first_line = "app.get<"
      assert.is_true(parser:is_content_valid_for_parsing(first_line))

      -- Type definition lines
      local type_line = "  { userId: string; postId: string },"
      assert.is_true(parser:is_content_valid_for_parsing(type_line))

      -- Closing line with path
      local closing_line = ">('/api/path', (req, res) => {"
      assert.is_true(parser:is_content_valid_for_parsing(closing_line))
    end)

    it("should extract method from multiline patterns", function()
      local multiline_content = [[app.post<
  RequestType<string, number>,
  ResponseType<ApiResponse<User[]>>
>('/super-complex', (req, res) => {]]

      local method = parser:extract_method(multiline_content)
      assert.equals("POST", method)
    end)

    it("should extract path from multiline patterns", function()
      local multiline_content = [[app.delete<
  { id: string },
  MessageResponse
>('/users/:id', (req, res) => {]]

      local path = parser:extract_endpoint_path(multiline_content, "test.ts", 100)
      assert.equals("/users/:id", path)
    end)

    it("should have high confidence for multiline generics", function()
      local multiline_content = [[app.patch<
  { id: string },
  ApiResponse<User>,
  Partial<UpdateUserRequest>
>('/users/:id', (req, res) => {]]

      local confidence = parser:get_parsing_confidence(multiline_content)
      assert.is_true(confidence >= 0.9)
    end)
  end)

  describe("Comment Filtering", function()
    it("should have comment patterns configured", function()
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
      local commented_content = '// app.get<{}, MessageResponse>("/commented", (req, res) => {'
      local result = framework:parse(commented_content, "test.ts", 1, 1)
      assert.is_nil(result, "Single-line commented endpoint should be filtered out")
    end)

    it("should filter out block commented endpoints", function()
      local commented_content = '* router.post<{}, ApiResponse<User>>("/block-commented", (req, res) => {'
      local result = framework:parse(commented_content, "test.ts", 1, 1)
      assert.is_nil(result, "Block commented endpoint should be filtered out")
    end)

    it("should allow active endpoints", function()
      local active_content = 'app.get<{}, MessageResponse>("/active", (req, res) => {'
      local result = framework:parse(active_content, "test.ts", 1, 1)
      assert.is_not_nil(result, "Active endpoint should be parsed")
      assert.equals("GET", result.method)
      assert.equals("/active", result.endpoint_path)
    end)

    it("should filter various TypeScript comment styles", function()
      local test_cases = {
        '// app.get<{}, MessageResponse>("/single-line", (req, res) => {',
        '    // router.post<{}, ApiResponse<User>>("/indented", (req, res) => {',
        '/* app.put<{ id: string }, ApiResponse<User>>("/block-start", (req, res) => { */',
        '* delete<{ id: string }, MessageResponse>("/block-inside", (req, res) => {',
      }

      for _, commented_content in ipairs(test_cases) do
        local result = framework:parse(commented_content, "test.ts", 1, 1)
        assert.is_nil(result, "Should filter: " .. commented_content)
      end
    end)
  end)
end)