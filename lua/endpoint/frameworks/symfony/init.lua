-- Symfony Framework Module
local framework = require "endpoint.framework"

---@type endpoint.framework_base
return framework:new("symfony"):setup {
  file_extensions = { "*.php" },
  exclude_patterns = { "**/vendor/**", "**/var/**" },
  detection = {
    files = { "composer.json", "symfony.lock", "config/routes.yaml", "src/Controller" },
    dependencies = { "symfony/framework-bundle", "symfony/routing", "symfony" },
    manifest_files = { "composer.json" },
  },
  type = "pattern",
  patterns = {
    GET = { "#\\[Route\\(.*methods.*GET", "@Route\\(.*methods.*GET", "\\* @Route\\(.*methods.*GET" },
    POST = { "#\\[Route\\(.*methods.*POST", "@Route\\(.*methods.*POST", "\\* @Route\\(.*methods.*POST" },
    PUT = { "#\\[Route\\(.*methods.*PUT", "@Route\\(.*methods.*PUT", "\\* @Route\\(.*methods.*PUT" },
    DELETE = { "#\\[Route\\(.*methods.*DELETE", "@Route\\(.*methods.*DELETE", "\\* @Route\\(.*methods.*DELETE" },
    PATCH = { "#\\[Route\\(.*methods.*PATCH", "@Route\\(.*methods.*PATCH", "\\* @Route\\(.*methods.*PATCH" },
  },
  parser = require "endpoint.frameworks.symfony.parser",
}