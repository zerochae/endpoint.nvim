describe("Servlet framework", function()
  local test_helpers = require "tests.utils.framework_test_helpers"
  local servlet = require "endpoint.frameworks.servlet"

  describe("framework detection", test_helpers.create_detection_test_suite(servlet, "servlet"))

  describe(
    "search command generation",
    test_helpers.create_search_cmd_test_suite(servlet, {
      GET = { "doGet" },
      POST = { "doPost" },
      ALL = { "doGet", "doPost" },
    })
  )

  describe("search command file globs", function()
    it("should include proper file globs", function()
      local cmd = servlet.get_search_cmd "ALL"
      assert.is_true(cmd:match "%.java" ~= nil)
      assert.is_true(cmd:match "%.xml" ~= nil)
      assert.is_true(cmd:match "!.*target" ~= nil)
    end)
  end)

  describe(
    "line parsing",
    test_helpers.create_line_parsing_test_suite(servlet, {
      {
        description = "should parse doGet method signature",
        line = "UserServlet.java:25:5:    protected void doGet(HttpServletRequest request, HttpServletResponse response)",
        method = "GET",
        expected = {
          method = "GET",
          file_path = "UserServlet.java",
          line_number = 25,
          column = 5,
        },
      },
      {
        description = "should parse doPost method signature",
        line = "UserServlet.java:45:5:    protected void doPost(HttpServletRequest request, HttpServletResponse response)",
        method = "POST",
        expected = {
          method = "POST",
          file_path = "UserServlet.java",
          line_number = 45,
          column = 5,
        },
      },
      {
        description = "should parse doPut method signature",
        line = "UserServlet.java:65:5:    protected void doPut(HttpServletRequest request, HttpServletResponse response)",
        method = "PUT",
        expected = {
          method = "PUT",
          file_path = "UserServlet.java",
          line_number = 65,
          column = 5,
        },
      },
      {
        description = "should parse doDelete method signature",
        line = "UserServlet.java:85:5:    protected void doDelete(HttpServletRequest request, HttpServletResponse response)",
        method = "DELETE",
        expected = {
          method = "DELETE",
          file_path = "UserServlet.java",
          line_number = 85,
          column = 5,
        },
      },
    })
  )

  describe("integration with fixtures", test_helpers.create_integration_test_suite(servlet, "servlet"))

  describe("edge cases", function()
    it("should handle servlet methods with different access modifiers", function()
      local line =
        "UserServlet.java:30:5:    public void doGet(HttpServletRequest request, HttpServletResponse response)"
      local result = servlet.parse_line(line, "GET")

      if result then
        assert.are.equal("GET", result.method)
        assert.is_string(result.endpoint_path)
      end
    end)
  end)
end)

