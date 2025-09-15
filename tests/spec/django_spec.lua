describe("Django framework", function()
  local test_helpers = require "tests.utils.framework_test_helpers"
  local django = require "endpoint.frameworks.django"

  describe("framework detection", test_helpers.create_detection_test_suite(django, "django"))

  describe(
    "search command generation",
    test_helpers.create_search_cmd_test_suite(django, {
      GET = { "path", "class.*View", "def.*get" },
      POST = { "path", "class.*View", "def.*post" },
      PUT = { "path", "class.*View", "def.*put" },
      DELETE = { "path", "class.*View", "def.*delete" },
      PATCH = { "path", "class.*View", "def.*patch" },
      ALL = { 
        "path", "re_path", "url",
        "class.*View", "class.*ViewSet",
        "def.*get", "def.*post"
      },
    })
  )

  describe(
    "line parsing",
    test_helpers.create_line_parsing_test_suite(django, {
      {
        description = "should parse function method definition",
        line = "tests/fixtures/django/users/views.py:9:1:def user_list(request):",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/", -- Function-specific endpoint from URL pattern
          file_path = "tests/fixtures/django/users/views.py",
          line_number = 9,
          column = 1,
        },
      },
      {
        description = "should parse POST method definition",
        line = "tests/fixtures/django/users/views.py:16:1:def create_user(request):",
        method = "POST",
        expected = {
          method = "POST",
          endpoint_path = "/create", -- Function-specific endpoint from URL pattern
          file_path = "tests/fixtures/django/users/views.py",
          line_number = 16,
          column = 1,
        },
      },
    })
  )

  describe("Search result filtering", function()
    it("should filter out URL pattern lines", function()
      local result = django.parse_line("tests/fixtures/django/api/urls.py:10:5:    path('status/', views.api_status, name='api_status'),", "GET")
      assert.is_nil(result, "URL pattern lines should be filtered out")
    end)
    
    it("should filter out re_path pattern lines", function()
      local result = django.parse_line("tests/fixtures/django/api/urls.py:20:5:    re_path(r'^posts/(?P<post_id>\\d+)/$', views.post_detail, name='post_detail'),", "GET")
      assert.is_nil(result, "re_path pattern lines should be filtered out")
    end)
    
    it("should filter out url pattern lines", function()
      local result = django.parse_line("tests/fixtures/django/api/urls.py:25:5:    url(r'^legacy/status/$', views.legacy_status, name='legacy_status'),", "GET")
      assert.is_nil(result, "url pattern lines should be filtered out")
    end)
    
    it("should filter out ViewSet class definitions", function()
      local result = django.parse_line("tests/fixtures/django/api/viewsets.py:5:1:class UserViewSet(viewsets.ModelViewSet):", "GET")
      assert.is_nil(result, "ViewSet class definitions should be filtered out")
    end)
    
    it("should allow Django CBV class definitions", function()
      local result = django.parse_line("tests/fixtures/django/users/views.py:25:1:class UserListView(ListView):", "GET")
      assert.is_not_nil(result, "Django CBV class definitions should be allowed")
      assert.are.equal("GET", result.method)
    end)
    
    it("should filter out comment lines", function()
      local result = django.parse_line("project/urls.py:8:35:    # Add a URL to urlpatterns:  path('', views.home, name='home')", "GET")
      assert.is_nil(result, "Comment lines should be filtered out")
    end)
    
    it("should filter out numbered documentation lines", function()
      local result = django.parse_line("project/urls.py:8:35:    2. Add a URL to urlpatterns:  path('', views.home, name='home')", "GET")
      assert.is_nil(result, "Numbered documentation lines should be filtered out")
    end)
  end)

  describe("URL path combining", function()
    it("should combine paths without double slashes", function()
      local result = django.combine_url_paths("/api", "/users")
      assert.are.equal("/api/users", result)
    end)
    
    it("should handle empty prefix", function()
      local result = django.combine_url_paths("", "/users")
      assert.are.equal("/users", result)
    end)
    
    it("should handle empty suffix", function()
      local result = django.combine_url_paths("/api", "")
      assert.are.equal("/api", result)
    end)
    
    it("should clean up multiple slashes", function()
      local result = django.combine_url_paths("/api/", "/users/")
      assert.are.equal("/api/users", result)
    end)
    
    it("should handle empty prefix properly", function()
      local result = django.combine_url_paths("", "/delete/{pk}")
      assert.are.equal("/delete/{pk}", result)
    end)
  end)

  describe("ViewSet URL generation", function()
    it("should generate collection URL for list action", function()
      local result = django.build_viewset_fallback_url("UserViewSet", "api/viewsets.py", "list")
      assert.are.equal("/api/user/", result)
    end)
    
    it("should generate collection URL for create action", function()
      local result = django.build_viewset_fallback_url("UserViewSet", "api/viewsets.py", "create")
      assert.are.equal("/api/user/", result)
    end)
    
    it("should generate detail URL for retrieve action", function()
      local result = django.build_viewset_fallback_url("UserViewSet", "api/viewsets.py", "retrieve")
      assert.are.equal("/api/user/{id}/", result)
    end)
    
    it("should generate detail URL for update action", function()
      local result = django.build_viewset_fallback_url("UserViewSet", "api/viewsets.py", "update")
      assert.are.equal("/api/user/{id}/", result)
    end)
    
    it("should generate detail URL for destroy action", function()
      local result = django.build_viewset_fallback_url("UserViewSet", "api/viewsets.py", "destroy")
      assert.are.equal("/api/user/{id}/", result)
    end)
    
    it("should generate detail URL for partial_update action", function()
      local result = django.build_viewset_fallback_url("UserViewSet", "api/viewsets.py", "partial_update")
      assert.are.equal("/api/user/{id}/", result)
    end)
  end)

  describe("Django path normalization", function()
    it("should normalize simple path", function()
      local result = django.normalize_django_path("api/users/")
      assert.are.equal("/api/users", result)
    end)
    
    it("should convert Django parameters", function()
      local result = django.normalize_django_path("users/<int:user_id>/")
      assert.are.equal("/users/{user_id}", result)
    end)
    
    it("should convert regex parameters", function() 
      local result = django.normalize_django_path("^posts/(?P<post_id>\\d+)/$")
      assert.are.equal("/posts/{post_id}", result)
    end)
    
    it("should handle root path", function()
      local result = django.normalize_django_path("")
      assert.are.equal("/", result)
    end)
    
    it("should remove regex anchors", function()
      local result = django.normalize_django_path("^api/status/$")
      assert.are.equal("/api/status", result)
    end)
    
    it("should handle complex parameters", function()
      local result = django.normalize_django_path("users/<str:username>/posts/<int:post_id>/")
      assert.are.equal("/users/{username}/posts/{post_id}", result)
    end)
  end)

  describe("HTTP method detection", function()
    it("should detect GET method from view name", function()
      local methods = django.analyze_view_methods("user_list", "tests/fixtures/django/users/urls.py")
      assert.is_true(vim.tbl_contains(methods, "GET"))
    end)
    
    it("should detect multiple methods for UpdateView", function()
      local methods = django.analyze_view_methods("UserUpdateView", "tests/fixtures/django/users/urls.py")
      assert.is_true(vim.tbl_contains(methods, "PUT"))
      assert.is_true(vim.tbl_contains(methods, "PATCH"))
    end)
    
    it("should default to GET for unknown views", function()
      local methods = django.analyze_view_methods("UnknownView", "tests/fixtures/django/users/urls.py")
      assert.are.same({"GET"}, methods)
    end)
  end)

  describe(
    "integration with fixtures",
    test_helpers.create_integration_test_suite(django, "django", function()
      -- Custom test for Django-specific behavior
      it("should detect Django project structure", function()
        local cwd = vim.fn.getcwd()
        -- Check if we're already in the Django directory
        local django_path = cwd:match("/django$") and cwd or (cwd .. "/tests/fixtures/django")
        if vim.fn.isdirectory(django_path) == 1 then
          vim.cmd("cd " .. django_path)
          
          local detected = django.detect()
          assert.is_true(detected, "Should detect Django project")
          
          vim.cmd("cd " .. cwd)
        end
      end)
      
      it("should find URL patterns in Django project", function()
        local cwd = vim.fn.getcwd()
        -- Check if we're already in the Django directory  
        local django_path = cwd:match("/django$") and cwd or (cwd .. "/tests/fixtures/django")
        if vim.fn.isdirectory(django_path) == 1 then
          vim.cmd("cd " .. django_path)
          
          local search_cmd = django.get_search_cmd("GET")
          assert.is_not_nil(search_cmd)
          assert.matches("path", search_cmd)
          
          vim.cmd("cd " .. cwd)
        end
      end)
    end)
  )
end)