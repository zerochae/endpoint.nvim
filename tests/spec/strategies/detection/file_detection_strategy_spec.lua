local FileDetectionStrategy = require "endpoint.core.strategies.detection.FileDetectionStrategy"
local strategy_generator = require "tests.helpers.strategy_scenario_generator"

describe("FileDetectionStrategy", function()
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

  -- Rails file detection config
  local rails_config = {
    name = "rails_file_detection",
    type = "file",
    init_params = {
      primary = {"Gemfile", "config/routes.rb", "config/application.rb"},
      secondary = nil,
      strategy_name = "rails_file_detection"
    },
    positive_test_files = {
      {
        path = "Gemfile",
        content = [[
source 'https://rubygems.org'
gem 'rails', '~> 7.0'
]]
      },
      {
        path = "config/routes.rb",
        content = [[
Rails.application.routes.draw do
  resources :users
end
]]
      }
    },
    negative_test_files = {
      {
        path = "package.json",
        content = '{"name": "not-rails", "dependencies": {}}'
      }
    }
  }

  -- Symfony file detection config
  local symfony_config = {
    name = "symfony_file_detection",
    type = "file",
    init_params = {
      primary = {"composer.json", "config/services.yaml", "symfony.lock"},
      secondary = nil,
      strategy_name = "symfony_file_detection"
    },
    positive_test_files = {
      {
        path = "composer.json",
        content = [[
{
  "require": {
    "symfony/framework-bundle": "^6.0"
  }
}
]]
      },
      {
        path = "symfony.lock",
        content = "{}"
      }
    },
    negative_test_files = {
      {
        path = "package.json",
        content = '{"name": "not-symfony"}'
      }
    }
  }

  describe("Rails File Detection", function()
    local scenarios = strategy_generator.generate_detection_scenarios(FileDetectionStrategy, rails_config)

    for scenario_name, scenario in pairs(scenarios) do
      it(scenario.description, function()
        if scenario.setup then
          scenario.setup(test_context)
        end
        scenario.test(FileDetectionStrategy, test_context)
      end)
    end
  end)

  describe("Symfony File Detection", function()
    local scenarios = strategy_generator.generate_detection_scenarios(FileDetectionStrategy, symfony_config)

    for scenario_name, scenario in pairs(scenarios) do
      it(scenario.description, function()
        if scenario.setup then
          scenario.setup(test_context)
        end
        scenario.test(FileDetectionStrategy, test_context)
      end)
    end
  end)
end)