local DjangoFramework = require "endpoint.frameworks.django"
local framework_generator = require "tests.helpers.framework_scenario_generator"

describe("DjangoFramework", function()
  local test_context

  before_each(function()
    test_context = {
      base_dir = vim.fn.tempname(),
      temp_files = {}
    }
    vim.fn.mkdir(test_context.base_dir, "p")
    vim.fn.mkdir(test_context.base_dir .. "/myproject", "p")
  end)

  after_each(function()
    -- Cleanup test files
    for _, temp_file in ipairs(test_context.temp_files) do
      if vim.fn.filereadable(temp_file) == 1 then
        vim.fn.delete(temp_file)
      end
    end
    if vim.fn.isdirectory(test_context.base_dir) == 1 then
      vim.fn.delete(test_context.base_dir, "rf")
    end
  end)

  local django_config = {
    name = "django",
    language = "python",
    detection = {
      manifest_files = {
        {
          file = "requirements.txt",
          content = "Django==4.2.0\ndjangorestframework==3.14.0"
        },
        {
          file = "pyproject.toml",
          content = '[tool.poetry.dependencies]\nDjango = "^4.2.0"'
        }
      }
    },
    parsing = {
      basic_examples = {
        {
          content = 'path("api/users/", UserListView.as_view(), name="user_list")',
          file = "urls.py",
          line = 10,
          column = 1,
          expected = {
            method = "GET",
            path = "api/users/"
          }
        },
        {
          content = 're_path(r"^api/posts/(?P<id>\\d+)/$", PostDetailView.as_view())',
          file = "urls.py",
          line = 15,
          column = 1,
          expected = {
            method = "GET",
            path = "^api/posts/(?P<id>\\d+)/$"
          }
        }
      },
      method_examples = {
        {
          content = 'path("api/users/", UserListView.as_view())',
          file = "urls.py",
          line = 10,
          column = 1
        }
      },
      parameter_examples = {
        {
          content = 'path("api/users/<int:user_id>/", UserDetailView.as_view())',
          file = "urls.py",
          line = 20,
          column = 1,
          expected = {
            path = "api/users/<int:user_id>/"
          }
        }
      },
      base_path_examples = {
        {
          content = 'path("", include("myapp.urls"))',
          file = "urls.py",
          line = 5,
          column = 1,
          expected = {
            full_path = ""
          }
        }
      },
      invalid_examples = {
        "",
        "# Comment only",
        "from django.urls import path",
        "urlpatterns = []"
      }
    },
    scanning = {
      source_files = {
        {
          file = "myproject/urls.py",
          content = [[
from django.urls import path, include
from . import views

urlpatterns = [
    path("api/users/", views.UserListView.as_view(), name="user_list"),
    path("api/users/<int:user_id>/", views.UserDetailView.as_view(), name="user_detail"),
    path("api/posts/", include("posts.urls")),
]
]]
        }
      }
    }
  }

  describe("Django Framework Tests", function()
    local scenarios = framework_generator.generate_framework_scenarios(DjangoFramework, django_config)

    for scenario_name, scenario in pairs(scenarios) do
      it(scenario.description, function()
        if scenario.setup then
          scenario.setup(test_context)
        end
        scenario.test(DjangoFramework, test_context)
      end)
    end
  end)
end)