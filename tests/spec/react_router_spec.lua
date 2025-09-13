describe("React Router framework", function()
  -- Ensure package path is available for module loading
  if _G.original_package_path then
    package.path = _G.original_package_path
  end
  local react_router = require "endpoint.frameworks.react_router"

  describe("framework detection", function()
    it("should detect React Router project", function()
      local fixture_path = "tests/fixtures/react_router"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local original_cwd = vim.fn.getcwd()
        vim.fn.chdir(fixture_path)

        local detected = react_router.detect()
        assert.is_true(detected)

        vim.fn.chdir(original_cwd)
      else
        pending "React Router fixture directory not found"
      end
    end)

    it("should not detect React Router in non-React directory", function()
      local temp_dir = "/tmp/non_react_" .. os.time()
      vim.fn.mkdir(temp_dir, "p")
      local original_cwd = vim.fn.getcwd()
      vim.fn.chdir(temp_dir)

      local detected = react_router.detect()
      assert.is_false(detected)

      vim.fn.chdir(original_cwd)
      vim.fn.delete(temp_dir, "rf")
    end)
  end)

  describe("search command generation", function()
    it("should generate search command for ROUTE method", function()
      local cmd = react_router.get_search_cmd "ROUTE"
      assert.is_string(cmd)
      assert.is_true(cmd:match "rg" ~= nil)
      assert.is_true(cmd:match "<Route" ~= nil or cmd:match "path:" ~= nil)
    end)

    it("should generate search command for ALL method", function()
      local cmd = react_router.get_search_cmd "ALL"
      assert.is_string(cmd)
      -- Should contain React Router patterns
      assert.is_true(cmd:match "Route" ~= nil)
      assert.is_true(cmd:match "navigate" ~= nil)
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
      -- Check if display_value includes component info
      if result.display_value then
        assert.is_true(result.display_value:match("Users") ~= nil)
      end
    end)

    it("should parse createBrowserRouter array format", function()
      local line = 'router.js:15:5:{ path: "/about", element: <About /> },'
      local result = react_router.parse_line(line, "ROUTE")

      assert.is_table(result)
      assert.are.equal("ROUTE", result and result.method)
      assert.are.equal("/about", result and result.endpoint_path)
      -- Check if display_value includes component info
      if result.display_value then
        assert.is_true(result.display_value:match("About") ~= nil)
      end
    end)

    it("should parse navigate function calls", function()
      local line = "Navigation.jsx:20:5:navigate('/login');"
      local result = react_router.parse_line(line, "ROUTE")

      assert.is_table(result)
      assert.are.equal("ROUTE", result and result.method)
      assert.are.equal("/login", result and result.endpoint_path)
    end)

    it("should parse Link components", function()
      local line = 'Navigation.jsx:25:5:<Link to="/about">About</Link>'
      local result = react_router.parse_line(line, "ROUTE")

      assert.is_table(result)
      assert.are.equal("ROUTE", result and result.method)
      assert.are.equal("/about", result and result.endpoint_path)
    end)

    it("should parse NavLink components", function()
      local line = 'Navigation.jsx:30:5:<NavLink to="/dashboard">Dashboard</NavLink>'
      local result = react_router.parse_line(line, "ROUTE")

      assert.is_table(result)
      assert.are.equal("ROUTE", result and result.method)
      assert.are.equal("/dashboard", result and result.endpoint_path)
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

    it("should handle routes without components", function()
      local line = "Navigation.jsx:15:5:navigate('/settings');"
      local result = react_router.parse_line(line, "ROUTE")

      if result then
        assert.are.equal("/settings", result and result.endpoint_path)
        -- Should not have component info for navigate calls
        assert.is_true(result.display_value == nil or not result.display_value:match("<.*/>"))
      end
    end)
  end)
end)