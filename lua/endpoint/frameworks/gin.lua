local Framework = require "endpoint.core.Framework"
local annotation_parser = require "endpoint.parser.annotation_parser"

---@class endpoint.GinFramework : endpoint.Framework
local GinFramework = setmetatable({}, { __index = Framework })
GinFramework.__index = GinFramework

---Creates a new GinFramework instance
function GinFramework:new()
  local gin_framework_instance = Framework.new(self, "gin", {
    file_extensions = { "*.go" },
    exclude_patterns = { "**/vendor", "**/node_modules" },
    patterns = {
      GET = { "r\\.GET\\(", "router\\.GET\\(" },
      POST = { "r\\.POST\\(", "router\\.POST\\(" },
      PUT = { "r\\.PUT\\(", "router\\.PUT\\(" },
      DELETE = { "r\\.DELETE\\(", "router\\.DELETE\\(" },
      PATCH = { "r\\.PATCH\\(", "router\\.PATCH\\(" },
    },
    search_options = { "--type", "go" },
    controller_extractors = {
      {
        pattern = "([^/]+)\\.go$",
        transform = function(name)
          return name:gsub("_controller$", ""):gsub("_handler$", "")
        end,
      },
    },
    detector = {
      dependencies = { "gin-gonic/gin", "github.com/gin-gonic/gin" },
      manifest_files = { "go.mod", "go.sum" },
      name = "gin_dependency_detection",
    },
    parser = annotation_parser,
  })
  setmetatable(gin_framework_instance, self)
  return gin_framework_instance
end


---Detects if Gin is present in the current project
function GinFramework:detect()
  return self.detector:is_target_detected()
end

---Parses Gin content to extract endpoint information
function GinFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parser:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- Enhance with Gin-specific metadata
    parsed_endpoint.tags = parsed_endpoint.tags or {}
    table.insert(parsed_endpoint.tags, "go")
    table.insert(parsed_endpoint.tags, "gin")

    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "gin"
    parsed_endpoint.metadata.language = "go"
  end

  return parsed_endpoint
end

return GinFramework
