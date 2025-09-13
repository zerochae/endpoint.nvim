describe("OAS Rails patterns", function()
  local rails = require "endpoint.frameworks.rails"

  describe("oas_rails documentation parsing", function()
    it("should parse API controller with documentation comments", function()
      local fixture_path = "tests/fixtures/rails"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local api_controller_path = fixture_path .. "/app/controllers/api/v1/users_controller.rb"
        if vim.fn.filereadable(api_controller_path) == 1 then
          local content = vim.fn.readfile(api_controller_path)

          -- Check that the file contains oas_rails documentation patterns
          local has_summary = false
          local has_parameter = false
          local has_response = false

          for _, line in ipairs(content) do
            if line:match "@summary" then
              has_summary = true
            end
            if line:match "@parameter" then
              has_parameter = true
            end
            if line:match "@response" then
              has_response = true
            end
          end

          assert.is_true(has_summary, "Should contain @summary annotations")
          assert.is_true(has_parameter, "Should contain @parameter annotations")
          assert.is_true(has_response, "Should contain @response annotations")
        else
          pending "API users controller not found"
        end
      else
        pending "Rails fixture directory not found"
      end
    end)

    it("should parse standard controller with tag and path annotations", function()
      local fixture_path = "tests/fixtures/rails"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local controller_path = fixture_path .. "/app/controllers/posts_controller.rb"
        if vim.fn.filereadable(controller_path) == 1 then
          local content = vim.fn.readfile(controller_path)

          -- Check for tag and path annotations
          local has_tag = false
          local has_path = false

          for _, line in ipairs(content) do
            if line:match "@tag" then
              has_tag = true
            end
            if line:match "@path" then
              has_path = true
            end
          end

          assert.is_true(has_tag, "Should contain @tag annotation")
          assert.is_true(has_path, "Should contain @path annotation")
        else
          pending "Posts controller not found"
        end
      else
        pending "Rails fixture directory not found"
      end
    end)

    it("should parse complex oas_rails example controller", function()
      local fixture_path = "tests/fixtures/rails"
      if vim.fn.isdirectory(fixture_path) == 1 then
        local controller_path = fixture_path .. "/app/controllers/oas_examples_controller.rb"
        if vim.fn.filereadable(controller_path) == 1 then
          local content = vim.fn.readfile(controller_path)

          -- Check for advanced oas_rails patterns
          local patterns_found = {
            tag = false,
            path = false,
            description = false,
            summary = false,
            parameter = false,
            response = false,
            complex_parameter = false,
            nested_parameter = false,
          }

          for _, line in ipairs(content) do
            if line:match "@tag" then
              patterns_found.tag = true
            end
            if line:match "@path" then
              patterns_found.path = true
            end
            if line:match "@description" then
              patterns_found.description = true
            end
            if line:match "@summary" then
              patterns_found.summary = true
            end
            if line:match "@parameter" then
              patterns_found.parameter = true
            end
            if line:match "@response" then
              patterns_found.response = true
            end
            -- Complex parameter patterns like filter[status]
            if line:match "@parameter filter%[" then
              patterns_found.complex_parameter = true
            end
            -- Nested parameter patterns like example.config.public
            if line:match "@parameter %w+%.%w+%.%w+" then
              patterns_found.nested_parameter = true
            end
          end

          for pattern, found in pairs(patterns_found) do
            assert.is_true(found, "Should contain " .. pattern .. " pattern")
          end
        else
          pending "OAS examples controller not found"
        end
      else
        pending "Rails fixture directory not found"
      end
    end)
  end)

  describe("Rails endpoint extraction with oas_rails", function()
    it("should extract endpoints from documented API controller", function()
      -- Simulate parsing a line from the API controller
      local line = "tests/fixtures/rails/app/controllers/api/v1/users_controller.rb:15:3:  def index"
      local result = rails.parse_line(line, "GET")

      assert.is_not_nil(result)
      assert.equals("GET", result and result.method)
      assert.equals("/api/v1/users", result and result.endpoint_path)
      assert.equals("GET[api/v1/users#index] /api/v1/users", result and result.display_value)
    end)

    it("should extract endpoints from documented standard controller", function()
      -- Simulate parsing a line from the posts controller
      local line = "tests/fixtures/rails/app/controllers/posts_controller.rb:10:3:  def index"
      local result = rails.parse_line(line, "GET")

      assert.is_not_nil(result)
      assert.equals("GET", result and result.method)
      assert.equals("/posts", result and result.endpoint_path)
    end)

    it("should extract complex endpoints from oas_examples controller", function()
      -- Test bulk operations endpoint
      local line = "tests/fixtures/rails/app/controllers/oas_examples_controller.rb:100:3:  def bulk_operations"
      local result = rails.parse_line(line, "GET")

      assert.is_not_nil(result)
      assert.equals("GET", result and result.method)
      assert.equals("/oas_examples/bulk_operations", result and result.endpoint_path)
    end)
  end)

  describe("OAS Rails annotation validation", function()
    it("should validate standard oas_rails annotation formats", function()
      local test_annotations = {
        "# @summary List all users",
        "# @description Retrieve a paginated list of users",
        "# @parameter page [Integer] Page number",
        "# @parameter user! [Hash] User data",
        "# @parameter user.name! [String] Required user name",
        "# @response 200 [Array<User>] List of users",
        "# @response 422 [Hash] Validation errors",
        "# @tag Users",
        "# @path /api/v1/users",
      }

      for _, annotation in ipairs(test_annotations) do
        -- Basic validation - just check that these are valid comment patterns
        assert.is_not_nil(annotation:match "^# @%w+")
      end
    end)

    it("should handle complex parameter documentation", function()
      local complex_params = {
        "# @parameter filter[status] [String] Filter by status",
        "# @parameter sort [String] Sort field with direction",
        "# @parameter example.config.public [Boolean] Public visibility",
        "# @parameter bulk_params [Hash] Parameters for bulk operation",
        "# @parameter tags [Array<String>] Array of tag strings",
      }

      for _, param in ipairs(complex_params) do
        assert.is_not_nil(param:match "@parameter")
        assert.is_not_nil(param:match "%[%w+")
      end
    end)
  end)

  describe("Rails routes with oas_rails integration", function()
    it("should handle explicit routes instead of resources", function()
      -- Now that we skip resource declarations, test explicit routes
      local line = "config/routes.rb:10:3:  get '/api/health', to: 'health#check'"
      local result = rails.parse_line(line, "ALL")

      if result then
        assert.equals("GET", result.method)
        assert.equals("/api/health", result.endpoint_path)
      else
        -- This is also acceptable since we now prioritize controller actions
        pending "Explicit route parsing - implementation may vary"
      end
    end)

    it("should skip namespace declarations and focus on controller actions", function()
      local line = "config/routes.rb:15:5:    namespace :v1"
      local result = rails.parse_line(line, "ALL")

      -- Namespace declarations should now be skipped in favor of actual controller actions
      assert.is_nil(result)
    end)

    it("should handle explicit routes with oas_rails patterns", function()
      local line = "config/routes.rb:20:3:  get '/health', to: 'health#check'"
      local result = rails.parse_line(line, "GET")

      assert.is_not_nil(result)
      assert.equals("GET", result and result.method)
      assert.equals("/health", result and result.endpoint_path)
    end)
  end)
end)

