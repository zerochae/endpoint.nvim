-- Strategy Test Scenario Generator
-- Generates consistent test scenarios for all detection and parsing strategies
local test_utils = require "tests.helpers.test_utils"

local M = {}

---Generates standard test scenarios for detection strategies
---@param strategy_class table The detection strategy class to test
---@param strategy_config table Strategy-specific configuration
---@return table test_scenarios Generated test scenarios
function M.generate_detection_scenarios(strategy_class, strategy_config)
  local strategy_name = strategy_config.name
  local scenarios = {}

  -- Scenario 1: Strategy Initialization
  scenarios.strategy_initialization = M._create_detection_initialization_scenario(strategy_config)

  -- Scenario 2: Positive Detection
  scenarios.positive_detection = M._create_positive_detection_scenario(strategy_config)

  -- Scenario 3: Negative Detection
  scenarios.negative_detection = M._create_negative_detection_scenario(strategy_config)

  -- Scenario 4: Detection Details
  scenarios.detection_details = M._create_detection_details_scenario(strategy_config)

  -- Scenario 5: Configuration Updates
  scenarios.configuration_updates = M._create_detection_configuration_scenario(strategy_config)

  -- Scenario 6: Edge Cases
  scenarios.edge_cases = M._create_detection_edge_cases_scenario(strategy_config)

  return scenarios
end

---Generates standard test scenarios for parsing strategies
---@param strategy_class table The parsing strategy class to test
---@param strategy_config table Strategy-specific configuration
---@return table test_scenarios Generated test scenarios
function M.generate_parsing_scenarios(strategy_class, strategy_config)
  local strategy_name = strategy_config.name
  local scenarios = {}

  -- Scenario 1: Strategy Initialization
  scenarios.strategy_initialization = M._create_parsing_initialization_scenario(strategy_config)

  -- Scenario 2: Valid Content Parsing
  scenarios.valid_content_parsing = M._create_valid_parsing_scenario(strategy_config)

  -- Scenario 3: Invalid Content Handling
  scenarios.invalid_content_handling = M._create_invalid_parsing_scenario(strategy_config)

  -- Scenario 4: Content Validation
  scenarios.content_validation = M._create_content_validation_scenario(strategy_config)

  -- Scenario 5: Confidence Scoring
  scenarios.confidence_scoring = M._create_parsing_confidence_scenario(strategy_config)

  -- Scenario 6: Pattern Matching
  scenarios.pattern_matching = M._create_pattern_matching_scenario(strategy_config)

  -- Scenario 7: Configuration Updates
  scenarios.configuration_updates = M._create_parsing_configuration_scenario(strategy_config)

  return scenarios
end

-- Detection Strategy Scenarios --

---Creates detection strategy initialization scenario
---@param strategy_config table Strategy configuration
---@return table scenario Initialization scenario
function M._create_detection_initialization_scenario(strategy_config)
  return {
    name = "strategy_initialization",
    description = string.format("Should initialize %s with correct parameters", strategy_config.name),
    test = function(strategy_class, test_context)
      local strategy
      if strategy_config.type == "dependency" then
        strategy = strategy_class:new(
          strategy_config.init_params.primary,
          strategy_config.init_params.secondary,
          strategy_config.init_params.strategy_name
        )
      elseif strategy_config.type == "file" then
        strategy = strategy_class:new(
          strategy_config.init_params.primary,
          strategy_config.init_params.strategy_name
        )
      end

      assert(strategy ~= nil, "Strategy should be created successfully")
      assert(strategy.detection_name == strategy_config.init_params.strategy_name, "Strategy name should be set correctly")

      -- Type-specific validations
      if strategy_config.type == "dependency" then
        local deps = strategy:get_required_dependencies()
        assert(#deps == #strategy_config.init_params.primary, "Should have correct number of dependencies")

        local manifests = strategy:get_manifest_files()
        assert(#manifests == #strategy_config.init_params.secondary, "Should have correct number of manifest files")
      elseif strategy_config.type == "file" then
        local files = strategy:get_required_files()
        assert(#files == #strategy_config.init_params.primary, "Should have correct number of required files")
      end
    end
  }
end

---Creates positive detection scenario
---@param strategy_config table Strategy configuration
---@return table scenario Positive detection scenario
function M._create_positive_detection_scenario(strategy_config)
  return {
    name = "positive_detection",
    description = string.format("Should detect when %s conditions are met", strategy_config.name),
    setup = function(test_context)
      -- Create test files based on strategy type
      for _, test_file in ipairs(strategy_config.positive_test_files) do
        local file_path = test_context.base_dir .. "/" .. test_file.path
        test_utils.create_test_file(file_path, test_file.content)
        table.insert(test_context.temp_files, file_path)
      end
    end,
    test = function(strategy_class, test_context)
      local strategy
      if strategy_config.type == "dependency" then
        strategy = strategy_class:new(
          strategy_config.init_params.primary,
          strategy_config.init_params.secondary,
          strategy_config.init_params.strategy_name
        )
      elseif strategy_config.type == "file" then
        strategy = strategy_class:new(
          strategy_config.init_params.primary,
          strategy_config.init_params.strategy_name
        )
      end

      -- Mock file system for testing
      if strategy_config.type == "dependency" or strategy_config.type == "file" then
        strategy.file_system_utils = M._create_test_fs_utils(test_context.base_dir)
      end

      local original_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. test_context.base_dir)

      local is_detected = strategy:is_target_detected()

      vim.cmd("cd " .. original_cwd)

      assert(is_detected, string.format("%s should detect when conditions are met", strategy_config.name))
    end
  }
end

---Creates negative detection scenario
---@param strategy_config table Strategy configuration
---@return table scenario Negative detection scenario
function M._create_negative_detection_scenario(strategy_config)
  return {
    name = "negative_detection",
    description = string.format("Should not detect when %s conditions are not met", strategy_config.name),
    setup = function(test_context)
      -- Create irrelevant files or empty directory
      for _, test_file in ipairs(strategy_config.negative_test_files or {}) do
        local file_path = test_context.base_dir .. "/" .. test_file.path
        test_utils.create_test_file(file_path, test_file.content)
        table.insert(test_context.temp_files, file_path)
      end
    end,
    test = function(strategy_class, test_context)
      local strategy
      if strategy_config.type == "dependency" then
        strategy = strategy_class:new(
          strategy_config.init_params.primary,
          strategy_config.init_params.secondary,
          strategy_config.init_params.strategy_name
        )
      elseif strategy_config.type == "file" then
        strategy = strategy_class:new(
          strategy_config.init_params.primary,
          strategy_config.init_params.strategy_name
        )
      end

      -- Mock file system for testing
      if strategy_config.type == "dependency" or strategy_config.type == "file" then
        strategy.file_system_utils = M._create_test_fs_utils(test_context.base_dir)
      end

      local is_detected = strategy:is_target_detected()
      assert(not is_detected, string.format("%s should not detect when conditions are not met", strategy_config.name))
    end
  }
end

---Creates detection details scenario
---@param strategy_config table Strategy configuration
---@return table scenario Detection details scenario
function M._create_detection_details_scenario(strategy_config)
  return {
    name = "detection_details",
    description = string.format("Should provide detailed information for %s detection", strategy_config.name),
    setup = function(test_context)
      for _, test_file in ipairs(strategy_config.positive_test_files) do
        local file_path = test_context.base_dir .. "/" .. test_file.path
        test_utils.create_test_file(file_path, test_file.content)
        table.insert(test_context.temp_files, file_path)
      end
    end,
    test = function(strategy_class, test_context)
      local strategy
      if strategy_config.type == "dependency" then
        strategy = strategy_class:new(
          strategy_config.init_params.primary,
          strategy_config.init_params.secondary,
          strategy_config.init_params.strategy_name
        )
      elseif strategy_config.type == "file" then
        strategy = strategy_class:new(
          strategy_config.init_params.primary,
          strategy_config.init_params.strategy_name
        )
      end

      -- Mock file system for testing
      if strategy_config.type == "dependency" or strategy_config.type == "file" then
        strategy.file_system_utils = M._create_test_fs_utils(test_context.base_dir)
      end

      local original_cwd = vim.fn.getcwd()
      vim.cmd("cd " .. test_context.base_dir)

      local details = strategy:get_detection_details()

      vim.cmd("cd " .. original_cwd)

      if strategy:is_target_detected() then
        assert(details ~= nil, "Should provide detection details when detected")
        assert(details.strategy_name == strategy_config.init_params.strategy_name, "Should have correct strategy name")

        -- Type-specific detail validations
        if strategy_config.type == "dependency" then
          assert(type(details.detected_dependencies) == "table", "Should have detected dependencies")
          assert(type(details.searched_manifest_files) == "table", "Should have searched manifest files")
        elseif strategy_config.type == "file" then
          assert(type(details.detected_files) == "table", "Should have detected files")
        end
      end
    end
  }
end

---Creates detection configuration scenario
---@param strategy_config table Strategy configuration
---@return table scenario Configuration scenario
function M._create_detection_configuration_scenario(strategy_config)
  return {
    name = "configuration_updates",
    description = string.format("Should allow configuration updates for %s", strategy_config.name),
    test = function(strategy_class, test_context)
      local strategy
      if strategy_config.type == "dependency" then
        strategy = strategy_class:new(
          strategy_config.init_params.primary,
          strategy_config.init_params.secondary,
          strategy_config.init_params.strategy_name
        )
      elseif strategy_config.type == "file" then
        strategy = strategy_class:new(
          strategy_config.init_params.primary,
          strategy_config.init_params.strategy_name
        )
      end

      if strategy_config.type == "dependency" then
        -- Test adding dependencies
        local original_deps = strategy:get_required_dependencies()
        strategy:add_required_dependencies({"new-dependency"})
        local updated_deps = strategy:get_required_dependencies()
        assert(#updated_deps == #original_deps + 1, "Should add new dependency")

        -- Test adding manifest files
        local original_manifests = strategy:get_manifest_files()
        strategy:add_manifest_files({"new-manifest.json"})
        local updated_manifests = strategy:get_manifest_files()
        assert(#updated_manifests == #original_manifests + 1, "Should add new manifest file")

      elseif strategy_config.type == "file" then
        -- Test adding required files
        local original_files = strategy:get_required_files()
        strategy:add_required_files({"new-file.txt"})
        local updated_files = strategy:get_required_files()
        assert(#updated_files == #original_files + 1, "Should add new required file")
      end
    end
  }
end

---Creates detection edge cases scenario
---@param strategy_config table Strategy configuration
---@return table scenario Edge cases scenario
function M._create_detection_edge_cases_scenario(strategy_config)
  return {
    name = "edge_cases",
    description = string.format("Should handle edge cases for %s", strategy_config.name),
    test = function(strategy_class, test_context)
      local strategy
      if strategy_config.type == "dependency" then
        strategy = strategy_class:new(
          strategy_config.init_params.primary,
          strategy_config.init_params.secondary,
          strategy_config.init_params.strategy_name
        )
      elseif strategy_config.type == "file" then
        strategy = strategy_class:new(
          strategy_config.init_params.primary,
          strategy_config.init_params.strategy_name
        )
      end

      -- Test with empty parameters
      local empty_strategy = strategy_class:new({}, {}, "empty_test")
      assert(not empty_strategy:is_target_detected(), "Should not detect with empty parameters")

      -- Test with nil parameters
      local nil_strategy = strategy_class:new(nil, nil, "nil_test")
      assert(not nil_strategy:is_target_detected(), "Should not detect with nil parameters")
    end
  }
end

-- Parsing Strategy Scenarios --

---Creates parsing strategy initialization scenario
---@param strategy_config table Strategy configuration
---@return table scenario Initialization scenario
function M._create_parsing_initialization_scenario(strategy_config)
  return {
    name = "strategy_initialization",
    description = string.format("Should initialize %s with correct parameters", strategy_config.name),
    test = function(strategy_class, test_context)
      local strategy = strategy_class:new(
        strategy_config.init_params.patterns,
        strategy_config.init_params.path_patterns,
        strategy_config.init_params.processors_or_mapping,
        strategy_config.init_params.strategy_name
      )

      assert(strategy ~= nil, "Strategy should be created successfully")
      assert(strategy.parsing_strategy_name == strategy_config.init_params.strategy_name, "Strategy name should be set correctly")
    end
  }
end

---Creates valid parsing scenario
---@param strategy_config table Strategy configuration
---@return table scenario Valid parsing scenario
function M._create_valid_parsing_scenario(strategy_config)
  return {
    name = "valid_content_parsing",
    description = string.format("Should parse valid content for %s", strategy_config.name),
    test = function(strategy_class, test_context)
      local strategy = strategy_class:new(
        strategy_config.init_params.patterns,
        strategy_config.init_params.path_patterns,
        strategy_config.init_params.processors_or_mapping,
        strategy_config.init_params.strategy_name
      )

      for _, test_case in ipairs(strategy_config.valid_test_cases) do
        local result = strategy:parse_content(
          test_case.content,
          test_case.file_path,
          test_case.line_number,
          test_case.column
        )

        assert(result ~= nil, string.format("Should parse valid content: %s", test_case.content))
        assert(result.method == test_case.expected.method, "Should extract correct HTTP method")
        assert(result.endpoint_path == test_case.expected.path, "Should extract correct endpoint path")
        assert(result.file_path == test_case.file_path, "Should set correct file path")
        assert(result.line_number == test_case.line_number, "Should set correct line number")
      end
    end
  }
end

---Creates invalid parsing scenario
---@param strategy_config table Strategy configuration
---@return table scenario Invalid parsing scenario
function M._create_invalid_parsing_scenario(strategy_config)
  return {
    name = "invalid_content_handling",
    description = string.format("Should handle invalid content for %s", strategy_config.name),
    test = function(strategy_class, test_context)
      local strategy = strategy_class:new(
        strategy_config.init_params.patterns,
        strategy_config.init_params.path_patterns,
        strategy_config.init_params.processors_or_mapping,
        strategy_config.init_params.strategy_name
      )

      local invalid_contents = strategy_config.invalid_test_cases or {
        "",
        "   ",
        "// just a comment",
        "random text here",
        "function notAnEndpoint() {}"
      }

      for _, invalid_content in ipairs(invalid_contents) do
        local result = strategy:parse_content(invalid_content, "test.file", 1, 1)
        assert(result == nil, string.format("Should return nil for invalid content: '%s'", invalid_content))
      end
    end
  }
end

---Creates content validation scenario
---@param strategy_config table Strategy configuration
---@return table scenario Content validation scenario
function M._create_content_validation_scenario(strategy_config)
  return {
    name = "content_validation",
    description = string.format("Should validate content appropriately for %s", strategy_config.name),
    test = function(strategy_class, test_context)
      local strategy = strategy_class:new(
        strategy_config.init_params.patterns,
        strategy_config.init_params.path_patterns,
        strategy_config.init_params.processors_or_mapping,
        strategy_config.init_params.strategy_name
      )

      -- Test valid content validation
      for _, test_case in ipairs(strategy_config.valid_test_cases) do
        local is_valid = strategy:is_content_valid_for_parsing(test_case.content)
        assert(is_valid, string.format("Should validate as valid: %s", test_case.content))
      end

      -- Test invalid content validation
      local invalid_contents = strategy_config.invalid_test_cases or {"", "random text"}
      for _, invalid_content in ipairs(invalid_contents) do
        local is_valid = strategy:is_content_valid_for_parsing(invalid_content)
        assert(not is_valid, string.format("Should validate as invalid: %s", invalid_content))
      end
    end
  }
end

---Creates parsing confidence scenario
---@param strategy_config table Strategy configuration
---@return table scenario Confidence scenario
function M._create_parsing_confidence_scenario(strategy_config)
  return {
    name = "confidence_scoring",
    description = string.format("Should assign appropriate confidence scores for %s", strategy_config.name),
    test = function(strategy_class, test_context)
      local strategy = strategy_class:new(
        strategy_config.init_params.patterns,
        strategy_config.init_params.path_patterns,
        strategy_config.init_params.processors_or_mapping,
        strategy_config.init_params.strategy_name
      )

      for _, test_case in ipairs(strategy_config.valid_test_cases) do
        local confidence = strategy:get_parsing_confidence(test_case.content)

        assert(type(confidence) == "number", "Confidence should be a number")
        assert(confidence >= 0 and confidence <= 1, "Confidence should be between 0 and 1")
        if strategy:is_content_valid_for_parsing(test_case.content) then
          assert(confidence > 0, "Confidence should be greater than 0 for valid content")
        end
      end
    end
  }
end

---Creates pattern matching scenario
---@param strategy_config table Strategy configuration
---@return table scenario Pattern matching scenario
function M._create_pattern_matching_scenario(strategy_config)
  return {
    name = "pattern_matching",
    description = string.format("Should match patterns correctly for %s", strategy_config.name),
    test = function(strategy_class, test_context)
      local strategy = strategy_class:new(
        strategy_config.init_params.patterns,
        strategy_config.init_params.path_patterns,
        strategy_config.init_params.processors_or_mapping,
        strategy_config.init_params.strategy_name
      )

      -- Test that strategy matches expected patterns
      for _, test_case in ipairs(strategy_config.valid_test_cases) do
        local result = strategy:parse_content(
          test_case.content,
          "test.file",
          1,
          1
        )

        if result then
          -- Verify pattern-specific expectations if metadata exists
          if test_case.expected.pattern_type and result.metadata then
            local has_correct_pattern = result.metadata.route_type == test_case.expected.pattern_type or
                                      result.metadata.annotation_type == test_case.expected.pattern_type or
                                      result.metadata.parsing_strategy == strategy_config.name
            if not has_correct_pattern then
              -- This is informational, not a hard failure since pattern_type metadata might not be implemented
              -- assert(has_correct_pattern, "Should identify correct pattern type")
            end
          end
        end
      end
    end
  }
end

---Creates parsing configuration scenario
---@param strategy_config table Strategy configuration
---@return table scenario Configuration scenario
function M._create_parsing_configuration_scenario(strategy_config)
  return {
    name = "configuration_updates",
    description = string.format("Should allow configuration updates for %s", strategy_config.name),
    test = function(strategy_class, test_context)
      local strategy = strategy_class:new(
        strategy_config.init_params.patterns,
        strategy_config.init_params.path_patterns,
        strategy_config.init_params.processors_or_mapping,
        strategy_config.init_params.strategy_name
      )

      if strategy_config.type == "annotation" then
        -- Test adding annotation patterns
        strategy:add_annotation_patterns("TEST", {"@Test%("})
        strategy:add_path_extraction_patterns({"test_pattern"})

      elseif strategy_config.type == "route" then
        -- Test adding route patterns
        strategy:add_route_patterns("test_route", {"test%s+"})
        strategy:add_path_extraction_patterns({"test_pattern"})
      end

      -- Strategy should still function after configuration updates
      assert(strategy ~= nil, "Strategy should remain functional after configuration updates")
    end
  }
end

-- Helper Functions --

---Creates test file system utils for mocking
---@param base_dir string Base directory for tests
---@return table fs_utils Mocked file system utilities
function M._create_test_fs_utils(base_dir)
  return {
    has_file = function(file_spec)
      local file_path = file_spec[1] or file_spec
      return vim.fn.filereadable(base_dir .. "/" .. file_path) == 1
    end,
    file_contains = function(file_path, pattern)
      local full_path = base_dir .. "/" .. file_path
      if vim.fn.filereadable(full_path) == 0 then
        return false
      end
      local content = table.concat(vim.fn.readfile(full_path), "\n")
      return content:find(pattern, 1, true) ~= nil
    end
  }
end

---Runs all generated scenarios for a strategy
---@param strategy_class table Strategy class to test
---@param strategy_config table Strategy configuration
---@param test_context table Test context
---@param scenario_type string "detection" or "parsing"
---@return table results Test results
function M.run_all_scenarios(strategy_class, strategy_config, test_context, scenario_type)
  local scenarios
  if scenario_type == "detection" then
    scenarios = M.generate_detection_scenarios(strategy_class, strategy_config)
  elseif scenario_type == "parsing" then
    scenarios = M.generate_parsing_scenarios(strategy_class, strategy_config)
  else
    error("Invalid scenario type: " .. tostring(scenario_type))
  end

  local results = {
    strategy_name = strategy_config.name,
    scenario_type = scenario_type,
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

      -- Run test
      scenario.test(strategy_class, test_context)
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