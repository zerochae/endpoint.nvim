local Framework = require "endpoint.core.Framework"
local class = require "endpoint.lib.middleclass"
local SpringParser = require "endpoint.parser.spring_parser"

---@class endpoint.SpringFramework
local SpringFramework = class("SpringFramework", Framework)

---Creates a new SpringFramework instance
function SpringFramework:initialize()
  Framework.initialize(self, {
    name = "spring",
    config = {
      file_extensions = { "*.java", "*.kt" },
      exclude_patterns = { "**/target", "**/build", "**/.gradle" },
      patterns = {
        GET = { "@GetMapping", "@RequestMapping.*method.*=.*GET" },
        POST = { "@PostMapping", "@RequestMapping.*method.*=.*POST" },
        PUT = { "@PutMapping", "@RequestMapping.*method.*=.*PUT" },
        DELETE = { "@DeleteMapping", "@RequestMapping.*method.*=.*DELETE" },
        PATCH = { "@PatchMapping", "@RequestMapping.*method.*=.*PATCH" },
      },
      search_options = { "--case-sensitive", "--type", "java", "-U", "--multiline-dotall" },
      controller_extractors = {
        { pattern = "([^/]+)%.java$" },
        { pattern = "([^/]+)%.kt$" },
      },
      detector = {
        dependencies = { "spring-boot", "spring-web", "spring-webmvc", "org.springframework" },
        manifest_files = {
          "pom.xml",
          "build.gradle",
          "build.gradle.kts",
          "application.properties",
          "application.yml",
          "application.yaml",
        },
        name = "spring_dependency_detection",
      },
      parser = SpringParser,
    },
  })
end

return SpringFramework
