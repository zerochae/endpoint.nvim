local AnnotationParsingStrategy = require "endpoint.core.strategies.parsing.AnnotationParsingStrategy"
local strategy_generator = require "tests.helpers.strategy_scenario_generator"

describe("AnnotationParsingStrategy", function()
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

  -- Spring annotation parsing config
  local spring_config = {
    name = "spring_annotation_parsing",
    type = "annotation",
    init_params = {
      patterns = {
        GET = { "@GetMapping", "@RequestMapping" },
        POST = { "@PostMapping", "@RequestMapping" },
        PUT = { "@PutMapping", "@RequestMapping" },
        DELETE = { "@DeleteMapping", "@RequestMapping" }
      },
      path_patterns = {
        '["\']([^"\']+)["\']',        -- @GetMapping("/path")
        'value%s*=%s*["\']([^"\']+)["\']', -- @RequestMapping(value="/path")
        'path%s*=%s*["\']([^"\']+)["\']'   -- @RequestMapping(path="/path")
      },
      processors_or_mapping = {
        ["@GetMapping"] = "GET",
        ["@PostMapping"] = "POST",
        ["@PutMapping"] = "PUT",
        ["@DeleteMapping"] = "DELETE",
        ["@RequestMapping"] = "GET" -- Default to GET
      },
      strategy_name = "spring_annotation_parsing"
    },
    valid_test_cases = {
      {
        content = '@GetMapping("/api/users")',
        file_path = "UserController.java",
        line_number = 15,
        column = 5,
        expected = {
          method = "GET",
          path = "/api/users",
          pattern_type = "annotation"
        }
      },
      {
        content = '@PostMapping(value = "/api/users", produces = "application/json")',
        file_path = "UserController.java",
        line_number = 25,
        column = 5,
        expected = {
          method = "POST",
          path = "/api/users",
          pattern_type = "annotation"
        }
      },
      {
        content = '@RequestMapping(path = "/api/admin", method = RequestMethod.GET)',
        file_path = "AdminController.java",
        line_number = 10,
        column = 5,
        expected = {
          method = "GET",
          path = "/api/admin",
          pattern_type = "annotation"
        }
      }
    },
    invalid_test_cases = {
      "",
      "   ",
      "// Just a comment",
      "public class Controller {}",
      "private String field;",
      "@Override public void method() {}"
    }
  }

  -- Symfony annotation parsing config
  local symfony_config = {
    name = "symfony_annotation_parsing",
    type = "annotation",
    init_params = {
      patterns = {
        GET = { "#%[Route%(", "@Route%(" },
        POST = { "#%[Route%(", "@Route%(" },
        PUT = { "#%[Route%(", "@Route%(" },
        DELETE = { "#%[Route%(", "@Route%(" }
      },
      path_patterns = {
        '["\']([^"\']+)["\']',        -- #[Route("/path")]
        'path:%s*["\']([^"\']+)["\']' -- @Route(path="/path")
      },
      processors_or_mapping = {
        ["#%[Route%("] = "GET", -- Default to GET
        ["@Route%("] = "GET"
      },
      strategy_name = "symfony_annotation_parsing"
    },
    valid_test_cases = {
      {
        content = '#[Route("/api/users", methods: ["GET"])]',
        file_path = "UserController.php",
        line_number = 20,
        column = 5,
        expected = {
          method = "GET",
          path = "/api/users",
          pattern_type = "annotation"
        }
      },
      {
        content = '@Route(path="/api/posts", methods={"POST"})',
        file_path = "PostController.php",
        line_number = 15,
        column = 5,
        expected = {
          method = "GET", -- Default, will be overridden by methods parameter
          path = "/api/posts",
          pattern_type = "annotation"
        }
      }
    },
    invalid_test_cases = {
      "",
      "<?php",
      "// Comment only",
      "class Controller {}",
      "private $property;",
      "#[Override] public function method() {}"
    }
  }

  describe("Spring Annotation Parsing", function()
    local scenarios = strategy_generator.generate_parsing_scenarios(AnnotationParsingStrategy, spring_config)

    for scenario_name, scenario in pairs(scenarios) do
      it(scenario.description, function()
        if scenario.setup then
          scenario.setup(test_context)
        end
        scenario.test(AnnotationParsingStrategy, test_context)
      end)
    end
  end)

  describe("Symfony Annotation Parsing", function()
    local scenarios = strategy_generator.generate_parsing_scenarios(AnnotationParsingStrategy, symfony_config)

    for scenario_name, scenario in pairs(scenarios) do
      it(scenario.description, function()
        if scenario.setup then
          scenario.setup(test_context)
        end
        scenario.test(AnnotationParsingStrategy, test_context)
      end)
    end
  end)
end)