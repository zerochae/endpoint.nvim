local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
local SymfonyParser = require "endpoint.parser.symfony_parser"

---@class endpoint.SymfonyFramework
local SymfonyFramework = setmetatable({}, { __index = Framework })
SymfonyFramework.__index = SymfonyFramework

---Creates a new SymfonyFramework instance
function SymfonyFramework:new()
  local symfony_framework_instance = Framework.new(self, "symfony", {
    file_extensions = { "*.php" },
    exclude_patterns = { "**/vendor", "**/var", "**/cache" },
    patterns = {
      GET = { "#\\[Route\\(.*methods.*GET", "@Route\\(.*methods.*GET", "\\* @Route\\(.*methods.*GET" },
      POST = { "#\\[Route\\(.*methods.*POST", "@Route\\(.*methods.*POST", "\\* @Route\\(.*methods.*POST" },
      PUT = { "#\\[Route\\(.*methods.*PUT", "@Route\\(.*methods.*PUT", "\\* @Route\\(.*methods.*PUT" },
      DELETE = { "#\\[Route\\(.*methods.*DELETE", "@Route\\(.*methods.*DELETE", "\\* @Route\\(.*methods.*DELETE" },
      PATCH = { "#\\[Route\\(.*methods.*PATCH", "@Route\\(.*methods.*PATCH", "\\* @Route\\(.*methods.*PATCH" },
    },
    search_options = { "--case-sensitive", "--type", "php" },
    controller_patterns = {
      { pattern = "([^/]+)%.php$" }
    },
  })
  setmetatable(symfony_framework_instance, self)
  return symfony_framework_instance
end

---Sets up detection and parsing for Symfony
function SymfonyFramework:_initialize()
  -- Setup detector
  self.detector = DependencyDetector:new(
    { "symfony/framework-bundle", "symfony/symfony", "symfony" },
    { "composer.json", "composer.lock", "config/services.yaml", "config/routes.yaml" },
    "symfony_dependency_detection"
  )

  -- Setup Symfony-specific parser
  self.parser = SymfonyParser:new()
end

return SymfonyFramework