local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
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
    search_options = { "--case-sensitive", "--type", "java" },
  })
  setmetatable(spring_framework_instance, self)
  return spring_framework_instance
end

---Sets up detection and parsing for Spring
function SpringFramework:_initialize()
  -- Setup detector with improved logic from new backup
  self.detector = DependencyDetector:new(
    { "spring-boot", "spring-web", "spring-webmvc", "org.springframework" },
    { "pom.xml", "build.gradle", "build.gradle.kts", "application.properties", "application.yml", "application.yaml" },
    "spring_dependency_detection"
  )

  -- Setup Spring-specific parser
  self.parser = SpringParser:new()
end

---Detects if Spring is present in the current project
function SpringFramework:detect()
  if not self.detector then
    self:_initialize()
  end
  if self.detector then
    return self.detector:is_target_detected()
  end
  return false
end

---Extract controller name from Spring file path
function SpringFramework:getControllerName(file_path)
  -- Spring: UserController.java or UserController.kt → UserController
  return file_path:match "([^/]+)%.java$" or file_path:match "([^/]+)%.kt$"
end



return SpringFramework
