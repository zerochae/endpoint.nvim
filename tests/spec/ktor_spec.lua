local ktor = require "endpoint.frameworks.ktor"
local test_helpers = require "tests.utils.framework_test_helpers"

describe("Ktor framework", function()
  describe("framework detection", test_helpers.create_detection_test_suite(ktor, "ktor"))

  describe(
    "search command generation",
    test_helpers.create_search_cmd_test_suite(ktor, {
      GET = { "get" },
      POST = { "post" },
      PUT = { "put" },
      DELETE = { "delete" },
      PATCH = { "patch" },
      ALL = { "get", "post", "put", "delete", "patch" },
    })
  )

  describe(
    "line parsing",
    test_helpers.create_line_parsing_test_suite(ktor, {
      {
        description = "should parse basic get route",
        line = "src/main/kotlin/Main.kt:10:5:    get(\"/api/users\") {",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/users",
          file_path = "src/main/kotlin/Main.kt",
          line_number = 10,
          column = 5,
        },
      },
      {
        description = "should parse basic post route",
        line = "src/main/kotlin/Routes.kt:15:8:        post(\"/api/users\") {",
        method = "POST",
        expected = {
          method = "POST",
          endpoint_path = "/api/users",
          file_path = "src/main/kotlin/Routes.kt",
          line_number = 15,
          column = 8,
        },
      },
      {
        description = "should parse route with single quotes",
        line = "src/main/kotlin/Main.kt:20:5:    get('/api/health') {",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/health",
          file_path = "src/main/kotlin/Main.kt",
          line_number = 20,
          column = 5,
        },
      },
      {
        description = "should parse empty route in route block",
        line = "src/main/kotlin/Routes.kt:25:12:            get() {",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/",
          file_path = "src/main/kotlin/Routes.kt",
          line_number = 25,
          column = 12,
        },
      },
      {
        description = "should parse route with parameters",
        line = "src/main/kotlin/Routes.kt:30:8:        get(\"/users/{id}\") {",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/users/{id}",
          file_path = "src/main/kotlin/Routes.kt",
          line_number = 30,
          column = 8,
        },
      },
    })
  )

  describe("route extraction", function()
    it("should extract method and path from basic patterns", function()
      local method, path = ktor.extract_route_info("    get(\"/api/users\") {", "GET")
      assert.equals("GET", method)
      assert.equals("/api/users", path)
    end)

    it("should extract method and path from single quote patterns", function()
      local method, path = ktor.extract_route_info("    post('/api/orders') {", "POST")
      assert.equals("POST", method)
      assert.equals("/api/orders", path)
    end)

    it("should handle empty path patterns", function()
      local method, path = ktor.extract_route_info("        get() {", "GET")
      assert.equals("GET", method)
      assert.equals("/", path)
    end)

    it("should extract method from type-safe routing", function()
      local method, path = ktor.extract_route_info("    get<Articles> {", "GET")
      assert.equals("GET", method)
      assert.equals("/{resource}", path)
    end)
  end)

  describe("integration with fixtures", function()
    it("should correctly parse real Ktor fixture files", function()
      -- This would test with actual Ktor project files
      -- For now, just ensure the framework can handle complex scenarios
      local complex_line = "src/main/kotlin/Application.kt:45:16:                get(\"/api/v1/users/{id}/orders\") {"
      local result = ktor.parse_line(complex_line, "GET")
      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/api/v1/users/{id}/orders", result.endpoint_path)
    end)
  end)

  describe("edge cases", function()
    it("should handle routes with complex paths", function()
      local line = "src/main/kotlin/Routes.kt:50:12:    delete(\"/api/v2/users/{userId}/posts/{postId}\") {"
      local result = ktor.parse_line(line, "DELETE")
      assert.is_not_nil(result)
      assert.equals("DELETE", result.method)
      assert.equals("/api/v2/users/{userId}/posts/{postId}", result.endpoint_path)
    end)

    it("should handle mixed quote styles in different routes", function()
      local line1 = "src/main/kotlin/Routes.kt:60:8:    put(\"/users/{id}\") {"
      local line2 = "src/main/kotlin/Routes.kt:65:8:    patch('/users/{id}/status') {"
      
      local result1 = ktor.parse_line(line1, "PUT")
      local result2 = ktor.parse_line(line2, "PATCH")
      
      assert.is_not_nil(result1)
      assert.equals("PUT", result1.method)
      assert.equals("/users/{id}", result1.endpoint_path)
      
      assert.is_not_nil(result2)
      assert.equals("PATCH", result2.method)
      assert.equals("/users/{id}/status", result2.endpoint_path)
    end)

    it("should handle root path correctly", function()
      local line = "src/main/kotlin/Main.kt:15:5:    get(\"/\") {"
      local result = ktor.parse_line(line, "GET")
      assert.is_not_nil(result)
      assert.equals("GET", result.method)
      assert.equals("/", result.endpoint_path)
    end)
  end)
end)