local framework = require "endpoint.framework"

---@type endpoint.framework_base
return framework:new("spring"):setup {
  file_extensions = { "*.java", "*.kt" },
  exclude_patterns = { "**/target/**", "**/build/**", "**/.gradle/**" },
  detection = {
    files = { "src/main/java", "application.properties", "application.yml", "application.yaml" },
    dependencies = { "org.springframework.boot", "spring-boot", "spring-web", "spring-webmvc", "org.springframework" },
    manifest_files = { "build.gradle", "build.gradle.kts", "pom.xml" },
  },
  type = "pattern",
  patterns = {
    GET = { "@GetMapping", "@RequestMapping.*method.*=.*GET" },
    POST = { "@PostMapping", "@RequestMapping.*method.*=.*POST" },
    PUT = { "@PutMapping", "@RequestMapping.*method.*=.*PUT" },
    DELETE = { "@DeleteMapping", "@RequestMapping.*method.*=.*DELETE" },
    PATCH = { "@PatchMapping", "@RequestMapping.*method.*=.*PATCH" },
  },
  parser = require "endpoint.frameworks.spring.parser",
}
