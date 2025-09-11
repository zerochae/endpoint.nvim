return {
  file_patterns = { "**/*.java" },
  exclude_patterns = { "**/target/**", "**/build/**" },
  detection_files = { "pom.xml", "build.gradle", "application.properties", "application.yml" },
  patterns = {
    get = { "@GetMapping", "@RequestMapping.*method.*=.*GET" },
    post = { "@PostMapping", "@RequestMapping.*method.*=.*POST" },
    put = { "@PutMapping", "@RequestMapping.*method.*=.*PUT" },
    delete = { "@DeleteMapping", "@RequestMapping.*method.*=.*DELETE" },
    patch = { "@PatchMapping", "@RequestMapping.*method.*=.*PATCH" },
  },
}
