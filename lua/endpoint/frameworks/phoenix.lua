local Framework = require "endpoint.core.Framework"
local Detector = require "endpoint.core.Detector"
local annotation_parser = require "endpoint.parser.annotation_parser"

---@class endpoint.PhoenixFramework : endpoint.Framework
local PhoenixFramework = setmetatable({}, { __index = Framework })
PhoenixFramework.__index = PhoenixFramework

---Creates a new PhoenixFramework instance
function PhoenixFramework:new()
  local phoenix_framework_instance = Framework.new(self, "phoenix", {
    file_extensions = { "*.ex", "*.exs" },
    exclude_patterns = { "**/_build", "**/deps" },
    patterns = {
      GET = { "get\\s+['\"]", "resources\\s+['\"]" },
      POST = { "post\\s+['\"]", "resources\\s+['\"]" },
      PUT = { "put\\s+['\"]", "resources\\s+['\"]" },
      DELETE = { "delete\\s+['\"]", "resources\\s+['\"]" },
      PATCH = { "patch\\s+['\"]", "resources\\s+['\"]" },
    },
    search_options = { "--type", "elixir" }
  })
  setmetatable(phoenix_framework_instance, self)
  ---@cast phoenix_framework_instance PhoenixFramework
  return phoenix_framework_instance
end

---Sets up detection and parsing strategies for Phoenix
function PhoenixFramework:_initialize()
  -- Setup detector
  self.detector = dependency_detector:new(
    { "phoenix", ":phoenix" },
    { "mix.exs" },
    "phoenix_dependency_detection"
  )

  -- Setup parser with Phoenix route patterns
  local phoenix_annotation_patterns = {
    GET = { "get%s+", "resources%s+" },
    POST = { "post%s+", "resources%s+" },
    PUT = { "put%s+", "resources%s+" },
    DELETE = { "delete%s+", "resources%s+" },
    PATCH = { "patch%s+", "resources%s+" },
    OPTIONS = { "options%s+" },
    HEAD = { "head%s+" }
  }

  local phoenix_path_extraction_patterns = {
    '%s+["\']([^"\']+)["\']',     -- get "/path"
    'resources%s+["\']([^"\']+)["\']', -- resources "/users"
  }

  local phoenix_method_mapping = {
    ["get%s+"] = "GET",
    ["post%s+"] = "POST",
    ["put%s+"] = "PUT",
    ["delete%s+"] = "DELETE",
    ["patch%s+"] = "PATCH",
    ["resources%s+"] = "GET" -- Default for resources, will generate multiple
  }

  self.parser = annotation_parser:new(
    phoenix_annotation_patterns,
    phoenix_path_extraction_patterns,
    phoenix_method_mapping
  )
end

---Detects if Phoenix is present in the current project
function PhoenixFramework:detect()
  return self.detector:is_target_detected()
end

---Parses Phoenix content to extract endpoint information
function PhoenixFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parser:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- Phoenix-specific resource route handling
    if content:match("resources%s+") then
      local resource_name = content:match('resources%s+["\']([^"\']+)["\']')
      if resource_name then
        parsed_endpoint.endpoint_path = "/" .. resource_name
        parsed_endpoint.metadata = parsed_endpoint.metadata or {}
        parsed_endpoint.metadata.resource_name = resource_name
        parsed_endpoint.metadata.route_type = "resources"
      end
    end

    -- Enhance with Phoenix-specific metadata
    parsed_endpoint.tags = parsed_endpoint.tags or {}
    table.insert(parsed_endpoint.tags, "elixir")
    table.insert(parsed_endpoint.tags, "phoenix")

    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "phoenix"
    parsed_endpoint.metadata.language = "elixir"
  end

  return parsed_endpoint
end

return PhoenixFramework
