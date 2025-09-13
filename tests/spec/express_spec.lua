describe("Express framework", function()
  local test_helpers = require "tests.utils.framework_test_helpers"
  local express = require "endpoint.frameworks.express"

  describe("framework detection", test_helpers.create_detection_test_suite(express, "express"))

  describe(
    "search command generation",
    test_helpers.create_search_cmd_test_suite(express, {
      GET = { "app\\.get", "router\\.get" },
      POST = { "app\\.post", "router\\.post" },
      ALL = { "get", "post" },
    })
  )

  describe(
    "line parsing",
    test_helpers.create_line_parsing_test_suite(express, {
      {
        description = "should parse simple app.get line",
        line = "app.js:10:5:app.get('/api/users', (req, res) => {",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/users",
          file_path = "app.js",
          line_number = 10,
          column = 5,
        },
      },
      {
        description = "should parse router.post line",
        line = "routes/users.js:15:5:router.post('/', (req, res) => {",
        method = "POST",
        expected = {
          method = "POST",
          endpoint_path = "/",
          file_path = "routes/users.js",
          line_number = 15,
          column = 5,
        },
      },
      {
        description = "should parse routes with parameters",
        line = "app.js:20:5:app.get('/users/:id', (req, res) => {",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/users/:id",
          file_path = "app.js",
          line_number = 20,
          column = 5,
        },
      },
      {
        description = "should parse complex routes with multiple parameters",
        line = "app.js:25:5:app.get('/api/v1/users/:userId/posts/:postId', (req, res) => {",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/v1/users/:userId/posts/:postId",
          file_path = "app.js",
          line_number = 25,
          column = 5,
        },
      },
      {
        description = "should parse destructured method calls",
        line = "destructured.js:10:5:get('/api/home', (req, res) => {",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/home",
          file_path = "destructured.js",
          line_number = 10,
          column = 5,
        },
      },
      {
        description = "should parse destructured delete with del alias",
        line = "destructured.js:15:5:del('/api/users/:id', (req, res) => {",
        method = "DELETE",
        expected = {
          method = "DELETE",
          endpoint_path = "/api/users/:id",
          file_path = "destructured.js",
          line_number = 15,
          column = 5,
        },
      },
      {
        description = "should parse destructured patch method",
        line = "destructured.js:20:5:patch('/api/profile', (req, res) => {",
        method = "PATCH",
        expected = {
          method = "PATCH",
          endpoint_path = "/api/profile",
          file_path = "destructured.js",
          line_number = 20,
          column = 5,
        },
      },
    })
  )

  describe("additional parsing tests", function()
    it("should handle double quotes in routes", function()
      local line = 'app.js:30:5:app.post("/api/users", (req, res) => {'
      local result = express.parse_line(line, "POST")

      if result then
        assert.are.equal("POST", result and result.method)
        assert.are.equal("/api/users", result and result.endpoint_path)
      end
    end)
  end)

  describe("integration with fixtures", test_helpers.create_integration_test_suite(express, "express"))

  describe("edge cases", function()
    it("should handle various quote styles", function()
      local line1 = "app.js:10:5:app.get('/api/single', handler)"
      local line2 = 'app.js:11:5:app.get("/api/double", handler)'

      local result1 = express.parse_line(line1, "GET")
      local result2 = express.parse_line(line2, "GET")

      if result1 and result2 then
        assert.are.equal("/api/single", result1.endpoint_path)
        assert.are.equal("/api/double", result2.endpoint_path)
      end
    end)

    it("should handle path parameters correctly", function()
      local line = "routes/users.js:15:5:router.get('/:id/posts/:postId', handler)"
      local result = express.parse_line(line, "GET")

      if result then
        assert.are.equal("/:id/posts/:postId", result and result.endpoint_path)
      end
    end)

    it("should handle root path", function()
      local line = "app.js:5:5:app.get('/', (req, res) => {"
      local result = express.parse_line(line, "GET")

      if result then
        assert.are.equal("/", result and result.endpoint_path)
      end
    end)
  end)
end)

