local Framework = require "endpoint.core.Framework"
local class = require "endpoint.lib.middleclass"
local SpringParser = require "endpoint.parser.spring_parser"
local config = require "endpoint.config"

---@class endpoint.SpringFramework
local SpringFramework = class("SpringFramework", Framework)

---Creates a new SpringFramework instance
function SpringFramework:initialize()
  -- Determine which parser to use based on treesitter config
  ---@type table
  local parser_class = SpringParser
  local cfg = config.get()

  if cfg.treesitter and cfg.treesitter.enabled then
    local ok, SpringTreeSitterParser = pcall(require, "endpoint.parser.spring_treesitter_parser")
    if ok then
      local ts_parser = SpringTreeSitterParser:new()
      if ts_parser:is_available() then
        parser_class = SpringTreeSitterParser
      end
    end
  end

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
      parser = parser_class,
    },
  })
end

return SpringFramework
