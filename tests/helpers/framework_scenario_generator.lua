-- Framework Test Scenario Generator
-- Generates consistent test scenarios for all frameworks
local test_utils = require "tests.helpers.test_utils"

local M = {}

---Generates standard test scenarios for any framework
---@param framework_class table The framework class to test
---@param framework_config table Framework-specific configuration
---@return table test_scenarios Generated test scenarios
function M.generate_framework_scenarios(framework_class, framework_config)
  local framework_name = framework_config.name
  local scenarios = {}

  -- Scenario 1: Framework Detection
  scenarios.framework_detection = M._create_detection_scenario(framework_config)

  -- Scenario 2: No Framework Detection
  scenarios.no_framework_detection = M._create_no_detection_scenario(framework_config)

  -- Scenario 3: Basic Endpoint Parsing
  scenarios.basic_endpoint_parsing = M._create_basic_parsing_scenario(framework_config)

  -- Scenario 4: Multiple HTTP Methods
  scenarios.multiple_http_methods = M._create_multiple_methods_scenario(framework_config)

  -- Scenario 5: Path Parameters
  scenarios.path_parameters = M._create_path_parameters_scenario(framework_config)

  -- Scenario 6: Base Path Handling
  scenarios.base_path_handling = M._create_base_path_scenario(framework_config)

  -- Scenario 7: Invalid Content Handling
  scenarios.invalid_content_handling = M._create_invalid_content_scenario(framework_config)

  -- Scenario 8: Metadata Extraction
  scenarios.metadata_extraction = M._create_metadata_scenario(framework_config)

  -- Scenario 9: Confidence Scoring
  scenarios.confidence_scoring = M._create_confidence_scenario(framework_config)

  -- Scenario 10: Comprehensive Scan
  scenarios.comprehensive_scan = M._create_comprehensive_scan_scenario(framework_config)

  return scenarios
end

---Creates framework detection test scenario
---@param framework_config table Framework configuration
---@return table scenario Detection scenario
function M._create_detection_scenario(framework_config)
  return {
    name = "framework_detection",
    description = string.format("Should detect %s when dependencies are present", framework_config.name),
    setup = function(test_context)
      -- Create manifest files with dependencies
      for _, manifest_spec in ipairs(framework_config.detection.manifest_files) do
        local manifest_file = test_context.base_dir .. "/" .. manifest_spec.file
        test_utils.create_test_file(manifest_file, manifest_spec.content)
        table.insert(test_context.temp_files, manifest_file)
      end
    end,
    test = function(framework_instance, test_context)
      -- Change to test directory for proper detection
      local original_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. test_context.base_dir)

      local is_detected = framework_instance:detect()

      vim.cmd("cd " .. original_cwd)

      assert(is_detected, string.format("%s should be detected when dependencies are present", framework_config.name))
    end
  }
end

---Creates no framework detection test scenario
---@param framework_config table Framework configuration
---@return table scenario No detection scenario
function M._create_no_detection_scenario(framework_config)
  return {
    name = "no_framework_detection",
    description = string.format("Should not detect %s when dependencies are missing", framework_config.name),
    setup = function(test_context)
      -- Don't create any manifest files
    end,
    test = function(framework_instance, test_context)
      local is_detected = framework_instance:detect()
      assert(not is_detected, string.format("%s should not be detected when dependencies are missing", framework_config.name))
    end
  }
end

---Creates basic endpoint parsing test scenario
---@param framework_config table Framework configuration
---@return table scenario Basic parsing scenario
function M._create_basic_parsing_scenario(framework_config)
  return {
    name = "basic_endpoint_parsing",
    description = string.format("Should parse basic %s endpoint definitions", framework_config.name),
    setup = function(test_context)
      -- Setup handled in test function
    end,
    test = function(framework_instance, test_context)
      for _, endpoint_example in ipairs(framework_config.parsing.basic_examples) do
        local parsed_endpoint = framework_instance:parse(
          endpoint_example.content,
          test_context.base_dir .. "/" .. endpoint_example.file,
          endpoint_example.line,
          endpoint_example.column or 1
        )

        assert(parsed_endpoint ~= nil, string.format("Should parse: %s", endpoint_example.content))

        local is_valid, validation_error = test_utils.validate_endpoint_structure(parsed_endpoint, {
          method = endpoint_example.expected.method,
          endpoint_path = endpoint_example.expected.path
        })

        assert(is_valid, validation_error or "Endpoint structure validation failed")
      end
    end
  }
end

---Creates multiple HTTP methods test scenario
---@param framework_config table Framework configuration
---@return table scenario Multiple methods scenario
function M._create_multiple_methods_scenario(framework_config)
  return {
    name = "multiple_http_methods",
    description = string.format("Should parse different HTTP methods in %s", framework_config.name),
    setup = function(test_context)
      -- Setup handled in test function
    end,
    test = function(framework_instance, test_context)
      local found_methods = {}

      for _, method_example in ipairs(framework_config.parsing.method_examples) do
        local parsed_endpoint = framework_instance:parse(
          method_example.content,
          test_context.base_dir .. "/" .. method_example.file,
          method_example.line,
          method_example.column or 1
        )

        if parsed_endpoint then
          found_methods[parsed_endpoint.method] = true
        end
      end

      -- Should find multiple different HTTP methods
      local method_count = 0
      for _ in pairs(found_methods) do
        method_count = method_count + 1
      end

      assert(method_count >= 3, string.format("Should support multiple HTTP methods (found %d)", method_count))
    end
  }
end

---Creates path parameters test scenario
---@param framework_config table Framework configuration
---@return table scenario Path parameters scenario
function M._create_path_parameters_scenario(framework_config)
  return {
    name = "path_parameters",
    description = string.format("Should handle path parameters in %s", framework_config.name),
    setup = function(test_context)
      -- Setup handled in test function
    end,
    test = function(framework_instance, test_context)
      for _, param_example in ipairs(framework_config.parsing.parameter_examples) do
        local parsed_endpoint = framework_instance:parse(
          param_example.content,
          test_context.base_dir .. "/" .. param_example.file,
          param_example.line,
          param_example.column or 1
        )

        assert(parsed_endpoint ~= nil, string.format("Should parse parametrized endpoint: %s", param_example.content))
        assert(parsed_endpoint.endpoint_path == param_example.expected.path,
          string.format("Expected path %s, got %s", param_example.expected.path, parsed_endpoint.endpoint_path))
      end
    end
  }
end

---Creates base path handling test scenario
---@param framework_config table Framework configuration
---@return table scenario Base path scenario
function M._create_base_path_scenario(framework_config)
  return {
    name = "base_path_handling",
    description = string.format("Should combine base paths correctly in %s", framework_config.name),
    setup = function(test_context)
      -- Setup handled in test function
    end,
    test = function(framework_instance, test_context)
      for _, base_path_example in ipairs(framework_config.parsing.base_path_examples) do
        local parsed_endpoint = framework_instance:parse(
          base_path_example.content,
          test_context.base_dir .. "/" .. base_path_example.file,
          base_path_example.line,
          base_path_example.column or 1
        )

        assert(parsed_endpoint ~= nil, string.format("Should parse base path endpoint: %s", base_path_example.content))
        assert(parsed_endpoint.endpoint_path == base_path_example.expected.full_path,
          string.format("Expected full path %s, got %s", base_path_example.expected.full_path, parsed_endpoint.endpoint_path))
      end
    end
  }
end

---Creates invalid content handling test scenario
---@param framework_config table Framework configuration
---@return table scenario Invalid content scenario
function M._create_invalid_content_scenario(framework_config)
  return {
    name = "invalid_content_handling",
    description = string.format("Should handle invalid content gracefully in %s", framework_config.name),
    setup = function(test_context)
      -- Setup handled in test function
    end,
    test = function(framework_instance, test_context)
      local invalid_contents = framework_config.parsing.invalid_examples or {
        "",
        "   ",
        "// just a comment",
        "random text here",
        "function notAnEndpoint() {}"
      }

      for _, invalid_content in ipairs(invalid_contents) do
        local parsed_endpoint = framework_instance:parse(
          invalid_content,
          test_context.base_dir .. "/test_file",
          1,
          1
        )

        assert(parsed_endpoint == nil, string.format("Should return nil for invalid content: '%s'", invalid_content))
      end
    end
  }
end

---Creates metadata extraction test scenario
---@param framework_config table Framework configuration
---@return table scenario Metadata scenario
function M._create_metadata_scenario(framework_config)
  return {
    name = "metadata_extraction",
    description = string.format("Should extract proper metadata for %s", framework_config.name),
    setup = function(test_context)
      -- Setup handled in test function
    end,
    test = function(framework_instance, test_context)
      local example = framework_config.parsing.basic_examples[1]
      local parsed_endpoint = framework_instance:parse(
        example.content,
        test_context.base_dir .. "/" .. example.file,
        example.line,
        example.column or 1
      )

      assert(parsed_endpoint ~= nil, "Should parse endpoint for metadata test")
      if parsed_endpoint then
        assert(type(parsed_endpoint.tags) == "table", "Should have tags metadata")
        assert(type(parsed_endpoint.metadata) == "table", "Should have metadata table")

        -- Check framework name in metadata since it might not be a direct field
        local framework_name = parsed_endpoint.framework or
                              (parsed_endpoint.metadata and parsed_endpoint.metadata.framework_version)
        if framework_name then
          assert(framework_name == framework_config.name, "Should have correct framework name")
        end
      end

      -- Check framework-specific tags
      local has_framework_tag = false
      local has_language_tag = false

      for _, tag in ipairs(parsed_endpoint.tags) do
        if tag == framework_config.name then
          has_framework_tag = true
        end
        if tag == framework_config.language then
          has_language_tag = true
        end
      end

      assert(has_framework_tag, string.format("Should have %s tag", framework_config.name))
      assert(has_language_tag, string.format("Should have %s tag", framework_config.language))
    end
  }
end

---Creates confidence scoring test scenario
---@param framework_config table Framework configuration
---@return table scenario Confidence scenario
function M._create_confidence_scenario(framework_config)
  return {
    name = "confidence_scoring",
    description = string.format("Should assign appropriate confidence scores for %s", framework_config.name),
    setup = function(test_context)
      -- Setup handled in test function
    end,
    test = function(framework_instance, test_context)
      local example = framework_config.parsing.basic_examples[1]
      local parsed_endpoint = framework_instance:parse(
        example.content,
        test_context.base_dir .. "/" .. example.file,
        example.line,
        example.column or 1
      )

      if parsed_endpoint and parsed_endpoint.confidence then
        assert(type(parsed_endpoint.confidence) == "number", "Confidence should be a number")
        assert(parsed_endpoint.confidence >= 0 and parsed_endpoint.confidence <= 1,
          "Confidence should be between 0 and 1")
        assert(parsed_endpoint.confidence > 0.5, "Confidence should be reasonably high for valid endpoints")
      end
    end
  }
end

---Creates comprehensive scan test scenario
---@param framework_config table Framework configuration
---@return table scenario Comprehensive scan scenario
function M._create_comprehensive_scan_scenario(framework_config)
  return {
    name = "comprehensive_scan",
    description = string.format("Should perform comprehensive scan for %s", framework_config.name),
    setup = function(test_context)
      -- Create source files
      for _, source_spec in ipairs(framework_config.scanning.source_files) do
        local source_file = test_context.base_dir .. "/" .. source_spec.file
        test_utils.create_test_file(source_file, source_spec.content)
        table.insert(test_context.temp_files, source_file)
      end

      -- Create manifest files for detection
      for _, manifest_spec in ipairs(framework_config.detection.manifest_files) do
        local manifest_file = test_context.base_dir .. "/" .. manifest_spec.file
        test_utils.create_test_file(manifest_file, manifest_spec.content)
        table.insert(test_context.temp_files, manifest_file)
      end
    end,
    test = function(framework_instance, test_context)
      -- Change to test directory for scanning
      local original_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. test_context.base_dir)

      local scan_options = { force_refresh = true }
      local endpoints = framework_instance:scan(scan_options)

      vim.cmd("cd " .. original_cwd)

      -- Verify scan results
      assert(type(endpoints) == "table", "Scan should return a table of endpoints")
      -- Note: Actual endpoint count verification would require mocking ripgrep
      -- In real tests, we would mock the search command execution
    end
  }
end

---Runs all generated scenarios for a framework
---@param framework_class table Framework class to test
---@param framework_config table Framework configuration
---@param test_context table Test context
---@return table results Test results
function M.run_all_scenarios(framework_class, framework_config, test_context)
  local scenarios = M.generate_framework_scenarios(framework_class, framework_config)
  local results = {
    framework_name = framework_config.name,
    passed = 0,
    failed = 0,
    total = 0,
    scenario_results = {}
  }

  for scenario_name, scenario in pairs(scenarios) do
    local start_time = vim.loop.hrtime()
    local success, error_message = pcall(function()
      -- Setup scenario
      if scenario.setup then
        scenario.setup(test_context)
      end

      -- Create framework instance
      local framework_instance = framework_class:new()

      -- Run test
      scenario.test(framework_instance, test_context)
    end)

    local end_time = vim.loop.hrtime()
    local execution_time = (end_time - start_time) / 1e6 -- Convert to milliseconds

    local scenario_result = {
      name = scenario_name,
      description = scenario.description,
      passed = success,
      error_message = success and nil or error_message,
      execution_time = execution_time
    }

    results.scenario_results[scenario_name] = scenario_result
    results.total = results.total + 1

    if success then
      results.passed = results.passed + 1
    else
      results.failed = results.failed + 1
    end
  end

  return results
end

return M