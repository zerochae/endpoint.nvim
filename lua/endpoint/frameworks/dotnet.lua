local Framework = require "endpoint.core.Framework"
local DependencyDetectionStrategy = require "endpoint.core.strategies.detection.DependencyDetectionStrategy"
local AnnotationParsingStrategy = require "endpoint.core.strategies.parsing.AnnotationParsingStrategy"

---@class DotNetFramework : Framework
local DotNetFramework = setmetatable({}, { __index = Framework })
DotNetFramework.__index = DotNetFramework

---Creates a new DotNetFramework instance
---@return DotNetFramework
function DotNetFramework:new()
  local dotnet_framework_instance = Framework.new(self, "dotnet", {
    file_extensions = { "*.cs" },
    exclude_patterns = { "**/bin", "**/obj", "**/packages" },
    patterns = {
      GET = { "\\[HttpGet", "\\[Route.*HttpVerbs\\.Get" },
      POST = { "\\[HttpPost", "\\[Route.*HttpVerbs\\.Post" },
      PUT = { "\\[HttpPut", "\\[Route.*HttpVerbs\\.Put" },
      DELETE = { "\\[HttpDelete", "\\[Route.*HttpVerbs\\.Delete" },
      PATCH = { "\\[HttpPatch", "\\[Route.*HttpVerbs\\.Patch" },
    },
    search_options = { "--type", "csharp" }
  })
  setmetatable(dotnet_framework_instance, self)
  ---@cast dotnet_framework_instance DotNetFramework
  return dotnet_framework_instance
end

---Sets up detection and parsing strategies for .NET
---@protected
function DotNetFramework:_setup_strategies()
  -- Setup detection strategy
  self.detection_strategy = DependencyDetectionStrategy:new(
    { "Microsoft.AspNetCore", "Microsoft.AspNet.WebApi" },
    { "*.csproj", "packages.config", "project.json" },
    "dotnet_dependency_detection"
  )

  -- Setup parsing strategy with .NET attribute patterns
  local dotnet_annotation_patterns = {
    GET = { "%[HttpGet", "%[Route.*HttpVerbs%.Get" },
    POST = { "%[HttpPost", "%[Route.*HttpVerbs%.Post" },
    PUT = { "%[HttpPut", "%[Route.*HttpVerbs%.Put" },
    DELETE = { "%[HttpDelete", "%[Route.*HttpVerbs%.Delete" },
    PATCH = { "%[HttpPatch", "%[Route.*HttpVerbs%.Patch" },
    OPTIONS = { "%[HttpOptions", "%[Route.*HttpVerbs%.Options" },
    HEAD = { "%[HttpHead", "%[Route.*HttpVerbs%.Head" }
  }

  local dotnet_path_extraction_patterns = {
    '%[HttpGet%(["\']([^"\']+)["\']%)',      -- [HttpGet("/path")]
    '%[HttpPost%(["\']([^"\']+)["\']%)',     -- [HttpPost("/path")]
    '%[HttpPut%(["\']([^"\']+)["\']%)',      -- [HttpPut("/path")]
    '%[HttpDelete%(["\']([^"\']+)["\']%)',   -- [HttpDelete("/path")]
    '%[HttpPatch%(["\']([^"\']+)["\']%)',    -- [HttpPatch("/path")]
    '%[Route%(["\']([^"\']+)["\']',          -- [Route("/path")]
  }

  local dotnet_method_mapping = {
    ["%[HttpGet"] = "GET",
    ["%[HttpPost"] = "POST",
    ["%[HttpPut"] = "PUT",
    ["%[HttpDelete"] = "DELETE",
    ["%[HttpPatch"] = "PATCH",
    ["%[Route.*HttpVerbs%.Get"] = "GET",
    ["%[Route.*HttpVerbs%.Post"] = "POST",
    ["%[Route.*HttpVerbs%.Put"] = "PUT",
    ["%[Route.*HttpVerbs%.Delete"] = "DELETE",
    ["%[Route.*HttpVerbs%.Patch"] = "PATCH"
  }

  self.parsing_strategy = AnnotationParsingStrategy:new(
    dotnet_annotation_patterns,
    dotnet_path_extraction_patterns,
    dotnet_method_mapping
  )
end

---Detects if .NET is present in the current project
---@return boolean
function DotNetFramework:detect()
  return self.detection_strategy:is_target_detected()
end

---Parses .NET content to extract endpoint information
---@param content string The content to parse
---@param file_path string Path to the file
---@param line_number number Line number in the file
---@param column number Column number in the line
---@return endpoint.entry|nil
function DotNetFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parsing_strategy:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- Enhance with .NET-specific metadata
    parsed_endpoint.tags = parsed_endpoint.tags or {}
    table.insert(parsed_endpoint.tags, "csharp")
    table.insert(parsed_endpoint.tags, "dotnet")

    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "dotnet"
    parsed_endpoint.metadata.language = "csharp"

    -- Extract controller class name
    local controller_class_name = file_path:match("([^/]+)%.cs$")
    if controller_class_name then
      parsed_endpoint.metadata.controller_name = controller_class_name
    end
  end

  return parsed_endpoint
end

return DotNetFramework