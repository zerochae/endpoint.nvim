local Framework = require "endpoint.core.Framework"
local DependencyDetectionStrategy = require "endpoint.core.strategies.detection.DependencyDetectionStrategy"
local AnnotationParsingStrategy = require "endpoint.core.strategies.parsing.AnnotationParsingStrategy"

---@class endpoint.SymfonyFramework : endpoint.Framework
local SymfonyFramework = setmetatable({}, { __index = Framework })
SymfonyFramework.__index = SymfonyFramework

---Creates a new SymfonyFramework instance
function SymfonyFramework:new()
  local symfony_framework_instance = Framework.new(self, "symfony", {
    file_extensions = { "*.php" },
    exclude_patterns = { "**/vendor", "**/cache" },
    patterns = {
      GET = { "#\\[Route\\(", "@Route\\(" },
      POST = { "#\\[Route\\(", "@Route\\(" },
      PUT = { "#\\[Route\\(", "@Route\\(" },
      DELETE = { "#\\[Route\\(", "@Route\\(" },
      PATCH = { "#\\[Route\\(", "@Route\\(" },
    },
    search_options = { "--type", "php" }
  })
  setmetatable(symfony_framework_instance, self)
  ---@cast symfony_framework_instance SymfonyFramework
  return symfony_framework_instance
end

---Sets up detection and parsing strategies for Symfony
function SymfonyFramework:_setup_strategies()
  -- Setup detection strategy
  self.detection_strategy = DependencyDetectionStrategy:new(
    { "symfony/framework-bundle", "symfony/symfony" },
    { "composer.json" },
    "symfony_dependency_detection"
  )

  -- Setup parsing strategy with Symfony route patterns
  local symfony_annotation_patterns = {
    GET = { "#%[Route%(", "@Route%(" },
    POST = { "#%[Route%(", "@Route%(" },
    PUT = { "#%[Route%(", "@Route%(" },
    DELETE = { "#%[Route%(", "@Route%(" },
    PATCH = { "#%[Route%(", "@Route%(" },
    OPTIONS = { "#%[Route%(", "@Route%(" },
    HEAD = { "#%[Route%(", "@Route%(" }
  }

  local symfony_path_extraction_patterns = {
    '["\']([^"\']+)["\']',        -- #[Route("/path")]
    'path:%s*["\']([^"\']+)["\']', -- @Route(path="/path")
  }

  local symfony_method_mapping = {
    ["#%[Route%("] = "GET", -- Default to GET, will be overridden by methods parameter
    ["@Route%("] = "GET"
  }

  self.parsing_strategy = AnnotationParsingStrategy:new(
    symfony_annotation_patterns,
    symfony_path_extraction_patterns,
    symfony_method_mapping
  )
end

---Detects if Symfony is present in the current project
function SymfonyFramework:detect()
  return self.detection_strategy:is_target_detected()
end

---Parses Symfony content to extract endpoint information
function SymfonyFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parsing_strategy:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- Symfony-specific method extraction from methods parameter
    local methods_match = content:match('methods:%s*%[([^%]]+)%]')
    if methods_match then
      -- Extract first method from methods array
      local first_method = methods_match:match('["\']([^"\']+)["\']')
      if first_method then
        parsed_endpoint.method = first_method:upper()
        parsed_endpoint.display_value = parsed_endpoint.method .. " " .. parsed_endpoint.endpoint_path
      end
    end

    -- Enhance with Symfony-specific metadata
    parsed_endpoint.tags = parsed_endpoint.tags or {}
    table.insert(parsed_endpoint.tags, "php")
    table.insert(parsed_endpoint.tags, "symfony")

    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "symfony"
    parsed_endpoint.metadata.language = "php"
    parsed_endpoint.metadata.methods_parameter = methods_match
  end

  return parsed_endpoint
end

return SymfonyFramework
