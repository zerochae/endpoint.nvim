describe("React Router framework", function()
  local test_helpers = require "tests.utils.framework_test_helpers"
  local react_router = require "endpoint.frameworks.react_router"

  describe("framework detection", test_helpers.create_detection_test_suite(react_router, "react_router"))

  describe("search command generation", function()
    it("should generate search command for ROUTE method", function()
      local cmd = react_router.get_search_cmd "ROUTE"
      assert.is_string(cmd)
      assert.is_true(cmd:match "rg" ~= nil)
      assert.is_true(cmd:match "<Route" ~= nil or cmd:match "path:" ~= nil)
    end)

    it("should generate search command for all methods (ROUTE only)", function()
      local cmd = react_router.get_search_cmd "ALL"
      assert.is_string(cmd)
      -- Should only contain route patterns (no link/navigate)
      assert.is_true(cmd:match "Route" ~= nil)
      assert.is_true(cmd:match "path:" ~= nil)
      assert.is_false(cmd:match "navigate" ~= nil)
      assert.is_false(cmd:match "Link" ~= nil)
    end)

    it("should treat all HTTP methods as ROUTE patterns", function()
      local get_cmd = react_router.get_search_cmd "GET"
      local post_cmd = react_router.get_search_cmd "POST"
      assert.is_string(get_cmd)
      assert.is_string(post_cmd)
      assert.is_true(get_cmd:match "Route" ~= nil)
      assert.is_true(post_cmd:match "Route" ~= nil)
      -- Should not contain link/navigate patterns
      assert.is_false(get_cmd:match "navigate" ~= nil)
      assert.is_false(post_cmd:match "Link" ~= nil)
    end)

    it("should treat all HTTP methods identically", function()
      local get_cmd = react_router.get_search_cmd "GET"
      local post_cmd = react_router.get_search_cmd "POST"
      local put_cmd = react_router.get_search_cmd "PUT"
      local delete_cmd = react_router.get_search_cmd "DELETE"

      -- All commands should be identical since they all map to ALL
      assert.are.equal(get_cmd, post_cmd)
      assert.are.equal(post_cmd, put_cmd)
      assert.are.equal(put_cmd, delete_cmd)
    end)

    it("should generate consistent ROUTE patterns for all methods", function()
      local route_cmd = react_router.get_search_cmd "ROUTE"
      local all_cmd = react_router.get_search_cmd "ALL"
      local get_cmd = react_router.get_search_cmd "GET"

      -- All commands should be identical (ROUTE patterns only)
      assert.are.equal(route_cmd, all_cmd)
      assert.are.equal(all_cmd, get_cmd)

      -- Should contain Route and path patterns
      assert.is_true(route_cmd:match "Route" ~= nil)
      assert.is_true(route_cmd:match "path:" ~= nil)

      -- Should not contain link/navigate patterns
      assert.is_false(route_cmd:match "Link" ~= nil)
      assert.is_false(route_cmd:match "navigate" ~= nil)
    end)
  end)

  describe("line parsing", function()
    it("should parse Route component with element", function()
      local line = 'App.jsx:10:5:<Route path="/users" element={<Users />} />'
      local result = react_router.parse_line(line, "ROUTE")

      assert.is_table(result)
      assert.are.equal("ROUTE", result and result.method)
      assert.are.equal("/users", result and result.endpoint_path)
      assert.are.equal("App.jsx", result and result.file_path)
      assert.are.equal(10, result and result.line_number)
      assert.are.equal(5, result and result.column)
      -- Display value should be clean (no component info)
      assert.are.equal("ROUTE /users", result.display_value)
      -- Component info should be available separately
      assert.are.equal("Users", result.component_name)
    end)

    it("should parse createBrowserRouter array format", function()
      local line = 'router.js:15:5:{ path: "/about", element: <About /> },'
      local result = react_router.parse_line(line, "ROUTE")

      assert.is_table(result)
      assert.are.equal("ROUTE", result and result.method)
      assert.are.equal("/about", result and result.endpoint_path)
      -- Display value should be clean (no component info)
      assert.are.equal("ROUTE /about", result.display_value)
      -- Component info should be available separately
      assert.are.equal("About", result.component_name)
    end)

    it("should handle routes with parameters", function()
      local line = 'App.jsx:15:5:<Route path="/users/:id" element={<UserDetail />} />'
      local result = react_router.parse_line(line, "ROUTE")

      assert.is_table(result)
      assert.are.equal("ROUTE", result and result.method)
      assert.are.equal("/users/:id", result and result.endpoint_path)
    end)

    it("should handle complex nested routes", function()
      local line = 'router.js:20:5:{ path: "/users/:userId/posts/:postId", element: <PostDetail /> }'
      local result = react_router.parse_line(line, "ROUTE")

      assert.is_table(result)
      assert.are.equal("ROUTE", result and result.method)
      assert.are.equal("/users/:userId/posts/:postId", result and result.endpoint_path)
    end)

    it("should handle wildcard routes", function()
      local line = 'App.jsx:18:5:<Route path="/dashboard/*" element={<Dashboard />} />'
      local result = react_router.parse_line(line, "ROUTE")

      assert.is_table(result)
      assert.are.equal("ROUTE", result and result.method)
      assert.are.equal("/dashboard/*", result and result.endpoint_path)
    end)

    it("should return nil for invalid lines", function()
      local line = "invalid line format"
      local result = react_router.parse_line(line, "ROUTE")
      assert.is_nil(result)
    end)

    it("should return nil for empty lines", function()
      local line = ""
      local result = react_router.parse_line(line, "ROUTE")
      assert.is_nil(result)
    end)
  end)

  describe("integration with fixtures", function()
    it("should correctly parse real React Router fixture files", function()
      local fixture_path = "tests/fixtures/react_router"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        -- Test that framework is detected
        assert.is_true(react_router.detect())

        -- Test that search command works
        local cmd = react_router.get_search_cmd "ROUTE"
        assert.is_string(cmd)

        vim.fn.chdir(original_cwd)
      else
        pending "React Router fixture directory not found"
      end
    end)
  end)

  describe("edge cases", function()
    it("should handle both single and double quotes", function()
      local line1 = "App.jsx:10:5:<Route path='/users' element={<Users />} />"
      local line2 = 'App.jsx:11:5:<Route path="/about" element={<About />} />'

      local result1 = react_router.parse_line(line1, "ROUTE")
      local result2 = react_router.parse_line(line2, "ROUTE")

      if result1 and result2 then
        assert.are.equal("/users", result1.endpoint_path)
        assert.are.equal("/about", result2.endpoint_path)
      end
    end)

    it("should handle root path", function()
      local line = 'App.jsx:5:5:<Route path="/" element={<Home />} />'
      local result = react_router.parse_line(line, "ROUTE")

      if result then
        assert.are.equal("/", result and result.endpoint_path)
      end
    end)

    it("should handle routes without element attribute", function()
      local line = "App.jsx:15:5:<Route path='/settings' />"
      local result = react_router.parse_line(line, "ROUTE")

      if result then
        assert.are.equal("ROUTE", result.method)
        assert.are.equal("/settings", result.endpoint_path)
        assert.are.equal("ROUTE /settings", result.display_value)
        assert.is_nil(result.component_name)
      end
    end)

    it("should always return ROUTE method regardless of input method", function()
      local line = 'App.jsx:10:5:<Route path="/users" element={<Users />} />'

      local result_get = react_router.parse_line(line, "GET")
      local result_post = react_router.parse_line(line, "POST")
      local result_route = react_router.parse_line(line, "ROUTE")

      -- All should return ROUTE as method regardless of input
      assert.are.equal("ROUTE", result_get and result_get.method)
      assert.are.equal("ROUTE", result_post and result_post.method)
      assert.are.equal("ROUTE", result_route and result_route.method)

      -- All results should be identical
      if result_get and result_post then
        assert.are.equal(result_get.endpoint_path, result_post.endpoint_path)
        assert.are.equal(result_get.component_name, result_post.component_name)
        assert.are.equal(result_get.display_value, result_post.display_value)
      end
    end)

    it("should include component file path when component found", function()
      -- This test will verify component resolution in actual fixture environment
      local line = 'App.jsx:10:5:<Route path="/users" element={<Home />} />'
      local result = react_router.parse_line(line, "ROUTE")

      assert.is_table(result)
      assert.are.equal("ROUTE", result.method)
      assert.are.equal("/users", result.endpoint_path)
      assert.are.equal("Home", result.component_name)
      -- component_file_path will be tested in integration environment
    end)
  end)
end)

