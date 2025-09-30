local Framework = require "endpoint.core.Framework"
local SymfonyParser = require "endpoint.parser.symfony_parser"

---@class endpoint.SymfonyFramework
local SymfonyFramework = Framework:extend()

---Creates a new SymfonyFramework instance
function SymfonyFramework:new()
  SymfonyFramework.super.new(self, {
    name = "symfony",
    config = {
      file_extensions = { "*.php" },
      exclude_patterns = { "**/vendor", "**/var", "**/cache" },
      patterns = {
        GET = {
          "#\\[Route\\([^\\]]*methods[^\\]]*GET",
          "@Route\\(.*methods.*GET",
          "\\* @Route\\([^)]*methods[^)]*GET",
          "\\* @Route\\([\\s\\S]*?methods[\\s\\S]*?GET",
        },
        POST = {
          "#\\[Route\\([^\\]]*methods[^\\]]*POST",
          "@Route\\(.*methods.*POST",
          "\\* @Route\\([^)]*methods[^)]*POST",
          "\\* @Route\\([\\s\\S]*?methods[\\s\\S]*?POST",
        },
        PUT = {
          "#\\[Route\\([^\\]]*methods[^\\]]*PUT",
          "@Route\\(.*methods.*PUT",
          "\\* @Route\\([^)]*methods[^)]*PUT",
          "\\* @Route\\([\\s\\S]*?methods[\\s\\S]*?PUT",
        },
        DELETE = {
          "#\\[Route\\([^\\]]*methods[^\\]]*DELETE",
          "@Route\\(.*methods.*DELETE",
          "\\* @Route\\([^)]*methods[^)]*DELETE",
          "\\* @Route\\([\\s\\S]*?methods[\\s\\S]*?DELETE",
        },
        PATCH = {
          "#\\[Route\\([^\\]]*methods[^\\]]*PATCH",
          "@Route\\(.*methods.*PATCH",
          "\\* @Route\\([^)]*methods[^)]*PATCH",
          "\\* @Route\\([\\s\\S]*?methods[\\s\\S]*?PATCH",
        },
      },
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
    },
  })
end

return SymfonyFramework
