local DependencyDetectionStrategy = require "endpoint.core.strategies.detection.DependencyDetectionStrategy"
local strategy_generator = require "tests.helpers.strategy_scenario_generator"

describe("DependencyDetectionStrategy", function()
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

  -- Spring Boot dependency detection config
  local spring_config = {
    name = "spring_dependency_detection",
    type = "dependency",
    init_params = {
      primary = {"spring-boot", "spring-web"},
      secondary = {"pom.xml", "build.gradle"},
      strategy_name = "spring_dependency_detection"
    },
    positive_test_files = {
      {
        path = "pom.xml",
        content = [[
<project>
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot</artifactId>
    </dependency>
  </dependencies>
</project>
]]
      }
    },
    negative_test_files = {
      {
        path = "pom.xml",
        content = "<project><dependencies></dependencies></project>"
      }
    }
  }

  -- Django dependency detection config
  local django_config = {
    name = "django_dependency_detection",
    type = "dependency",
    init_params = {
      primary = {"Django", "django"},
      secondary = {"requirements.txt", "pyproject.toml", "Pipfile"},
      strategy_name = "django_dependency_detection"
    },
    positive_test_files = {
      {
        path = "requirements.txt",
        content = [[
Django==4.2.0
djangorestframework==3.14.0
]]
      }
    },
    negative_test_files = {
      {
        path = "requirements.txt",
        content = "flask==2.0.0\nfastapi==0.95.0"
      }
    }
  }

  describe("Spring Boot Detection", function()
    local scenarios = strategy_generator.generate_detection_scenarios(DependencyDetectionStrategy, spring_config)

    for scenario_name, scenario in pairs(scenarios) do
      it(scenario.description, function()
        if scenario.setup then
          scenario.setup(test_context)
        end
        scenario.test(DependencyDetectionStrategy, test_context)
      end)
    end
  end)

  describe("Django Detection", function()
    local scenarios = strategy_generator.generate_detection_scenarios(DependencyDetectionStrategy, django_config)

    for scenario_name, scenario in pairs(scenarios) do
      it(scenario.description, function()
        if scenario.setup then
          scenario.setup(test_context)
        end
        scenario.test(DependencyDetectionStrategy, test_context)
      end)
    end
  end)
end)