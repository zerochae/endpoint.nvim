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
        description = "should parse path() URL pattern",
        line = "tests/fixtures/django/api/urls.py:10:5:    path('status/', views.api_status, name='api_status'),",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/status",
          file_path = "tests/fixtures/django/api/urls.py",
          line_number = 10,
          column = 5,
        },
      },
      {
        description = "should parse path() with parameters",
        line = "tests/fixtures/django/api/urls.py:15:5:    path('users/<int:user_id>/', views.user_detail, name='user_detail'),",
        method = "GET",
        expected = {
          method = "GET", 
          endpoint_path = "/users/{user_id}",
          file_path = "tests/fixtures/django/api/urls.py",
          line_number = 15,
          column = 5,
        },
      },
      {
        description = "should parse re_path() with regex",
        line = "tests/fixtures/django/api/urls.py:20:5:    re_path(r'^posts/(?P<post_id>\\d+)/$', views.post_detail, name='post_detail'),",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/posts/{post_id}",
          file_path = "tests/fixtures/django/api/urls.py", 
          line_number = 20,
          column = 5,
        },
      },
      {
        description = "should parse url() legacy pattern",
        line = "tests/fixtures/django/api/urls.py:25:5:    url(r'^legacy/status/$', views.legacy_status, name='legacy_status'),",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/legacy/status",
          file_path = "tests/fixtures/django/api/urls.py",
          line_number = 25,
          column = 5,
        },
      },
      {
        description = "should parse class-based view",
        line = "tests/fixtures/django/users/views.py:15:1:class UserListView(ListView):",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = nil, -- Will be resolved from URLs
          file_path = "tests/fixtures/django/users/views.py",
          line_number = 15,
          column = 1,
        },
      },
      {
        description = "should parse ViewSet class",
        line = "tests/fixtures/django/api/viewsets.py:5:1:class UserViewSet(viewsets.ModelViewSet):",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/viewset", -- Placeholder for ViewSet
          file_path = "tests/fixtures/django/api/viewsets.py",
          line_number = 5,
          column = 1,
        },
      },
      {
        description = "should parse function method definition",
        line = "tests/fixtures/django/users/views.py:50:5:    def get(self, request):",
        method = "GET",
        expected = {
          method = "GET",
          endpoint_path = "/api/get", -- Function-specific endpoint
          file_path = "tests/fixtures/django/users/views.py",
          line_number = 50,
          column = 5,
        },
      },
      {
        description = "should parse POST method definition",
        line = "tests/fixtures/django/users/views.py:55:5:    def post(self, request):",
        method = "POST",
        expected = {
          method = "POST",
          endpoint_path = "/api/post", -- Function-specific endpoint
          file_path = "tests/fixtures/django/users/views.py",
          line_number = 55,
          column = 5,
        },
      },
    })
  )

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
        local django_path = cwd .. "/tests/fixtures/django"
        vim.cmd("cd " .. django_path)
        
        local detected = django.detect()
        assert.is_true(detected, "Should detect Django project")
        
        vim.cmd("cd " .. cwd)
      end)
      
      it("should find URL patterns in Django project", function()
        local cwd = vim.fn.getcwd() 
        local django_path = cwd .. "/tests/fixtures/django" 
        vim.cmd("cd " .. django_path)
        
        local search_cmd = django.get_search_cmd("GET")
        assert.is_not_nil(search_cmd)
        assert.matches("path", search_cmd)
        
        vim.cmd("cd " .. cwd)
      end)
    end)
  )
end)