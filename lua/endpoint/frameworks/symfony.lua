local Framework = require "endpoint.core.Framework"
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
    comment_patterns = { "^//", "^/%*", "^%*", "^#[^%[]" },
    search_options = { "--case-sensitive", "--type", "php", "-U", "--multiline-dotall" },
    controller_extractors = {
      { pattern = "([^/]+)%.php$" },
    },
    detector = {
      dependencies = { "symfony/framework-bundle", "symfony/symfony", "symfony" },
      manifest_files = { "composer.json", "composer.lock", "config/services.yaml", "config/routes.yaml" },
      name = "symfony_dependency_detection",
    },
    parser = SymfonyParser,
  })
  setmetatable(symfony_framework_instance, self)
  return symfony_framework_instance
end

return SymfonyFramework
