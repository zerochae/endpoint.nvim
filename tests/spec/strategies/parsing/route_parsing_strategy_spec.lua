local RouteParsingStrategy = require "endpoint.core.strategies.parsing.RouteParsingStrategy"
local strategy_generator = require "tests.helpers.strategy_scenario_generator"

describe("RouteParsingStrategy", function()
  local test_context

  before_each(function()
    test_context = {
      base_dir = vim.fn.tempname(),
      temp_files = {}
    }
    vim.fn.mkdir(test_context.base_dir, "p")
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

  -- Django route parsing config
  local django_config = {
    name = "django_route_parsing",
    type = "route",
    init_params = {
      patterns = {
        ["path_route"] = { "path%(" },
        ["re_path_route"] = { "re_path%(" },
        ["url_route"] = { "url%(" },
        ["include_route"] = { "include%(" }
      },
      path_patterns = {
        '["\']([^"\']+)["\']',  -- path("api/users/", ...)
        'r["\']([^"\']+)["\']'   -- re_path(r"^api/users/$", ...)
      },
      processors_or_mapping = {
        ["path_route"] = function(strategy, content, file_path, line_number, column, endpoint_path, http_method)
          return {
            method = "GET",
            endpoint_path = endpoint_path,
            file_path = file_path,
            line_number = line_number,
            column = column,
            display_value = "GET " .. endpoint_path,
            confidence = 0.8,
            tags = { "python", "django" },
            metadata = {
              framework_version = "django",
              language = "python",
              route_type = "path",
              parsing_strategy = "django_route_parsing"
            }
          }
        end
      },
      strategy_name = "django_route_parsing"
    },
    valid_test_cases = {
      {
        content = 'path("api/users/", UserListView.as_view(), name="user_list")',
        file_path = "urls.py",
        line_number = 10,
        column = 5,
        expected = {
          method = "GET",
          path = "api/users/",
          pattern_type = "path"
        }
      },
      {
        content = 're_path(r"^api/posts/(?P<id>\\d+)/$", PostDetailView.as_view())',
        file_path = "urls.py",
        line_number = 15,
        column = 5,
        expected = {
          method = "GET",
          path = "^api/posts/(?P<id>\\d+)/$",
          pattern_type = "re_path"
        }
      }
    },
    invalid_test_cases = {
      "",
      "# Comment only",
      "from django.urls import path",
      "urlpatterns = []",
      "class ViewClass: pass"
    }
  }

  -- Rails route parsing config
  local rails_config = {
    name = "rails_route_parsing",
    type = "route",
    init_params = {
      patterns = {
        ["get_route"] = { "get%s+" },
        ["post_route"] = { "post%s+" },
        ["resources_route"] = { "resources%s+:" }
      },
      path_patterns = {
        '%s+["\']([^"\']+)["\']',  -- get "/users"
        '%s+:([%w_]+)'            -- resources :users
      },
      processors_or_mapping = {
        ["get_route"] = function(strategy, content, file_path, line_number, column, endpoint_path, http_method)
          return {
            method = "GET",
            endpoint_path = endpoint_path:match("^/") and endpoint_path or "/" .. endpoint_path,
            file_path = file_path,
            line_number = line_number,
            column = column,
            display_value = "GET " .. endpoint_path,
            confidence = 0.8,
            tags = { "ruby", "rails" },
            metadata = {
              framework_version = "rails",
              language = "ruby",
              route_type = "verb",
              parsing_strategy = "rails_route_parsing"
            }
          }
        end,
        ["resources_route"] = function(strategy, content, file_path, line_number, column, endpoint_path, http_method)
          local resource_path = "/" .. endpoint_path
          return {
            method = "GET",
            endpoint_path = resource_path,
            file_path = file_path,
            line_number = line_number,
            column = column,
            display_value = "RESOURCES " .. resource_path,
            confidence = 0.9,
            tags = { "ruby", "rails", "resources" },
            metadata = {
              framework_version = "rails",
              language = "ruby",
              route_type = "resources",
              parsing_strategy = "rails_route_parsing"
            }
          }
        end
      },
      strategy_name = "rails_route_parsing"
    },
    valid_test_cases = {
      {
        content = 'get "/api/users", to: "users#index"',
        file_path = "routes.rb",
        line_number = 5,
        column = 1,
        expected = {
          method = "GET",
          path = "/api/users",
          pattern_type = "verb"
        }
      },
      {
        content = "resources :users",
        file_path = "routes.rb",
        line_number = 8,
        column = 1,
        expected = {
          method = "GET",
          path = "/users",
          pattern_type = "resources"
        }
      }
    },
    invalid_test_cases = {
      "",
      "# Comment only",
      "Rails.application.routes.draw do",
      "end",
      "class UsersController < ApplicationController"
    }
  }

  describe("Django Route Parsing", function()
    local scenarios = strategy_generator.generate_parsing_scenarios(RouteParsingStrategy, django_config)

    for scenario_name, scenario in pairs(scenarios) do
      it(scenario.description, function()
        if scenario.setup then
          scenario.setup(test_context)
        end
        scenario.test(RouteParsingStrategy, test_context)
      end)
    end
  end)

  describe("Rails Route Parsing", function()
    local scenarios = strategy_generator.generate_parsing_scenarios(RouteParsingStrategy, rails_config)

    for scenario_name, scenario in pairs(scenarios) do
      it(scenario.description, function()
        if scenario.setup then
          scenario.setup(test_context)
        end
        scenario.test(RouteParsingStrategy, test_context)
      end)
    end
  end)
end)
