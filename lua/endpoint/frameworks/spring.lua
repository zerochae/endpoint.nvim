local Framework = require "endpoint.core.Framework"
local SpringParser = require "endpoint.parser.spring_parser"

---@class endpoint.SpringFramework
local SpringFramework = setmetatable({}, { __index = Framework })
SpringFramework.__index = SpringFramework

---Creates a new SpringFramework instance
function SpringFramework:new()
  local spring_framework_instance = Framework.new(self, "spring", {
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
  })
  setmetatable(spring_framework_instance, self)
  return spring_framework_instance
end

return SpringFramework
