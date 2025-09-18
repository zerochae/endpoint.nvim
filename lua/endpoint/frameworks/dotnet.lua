local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
local annotation_parser = require "endpoint.parser.annotation_parser"

---@class endpoint.DotNetFramework : endpoint.Framework
local DotNetFramework = setmetatable({}, { __index = Framework })
DotNetFramework.__index = DotNetFramework

---Creates a new DotNetFramework instance
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
function DotNetFramework:_initialize()
  -- Setup detector
  self.detector = dependency_detector:new(
    { "Microsoft.AspNetCore", "Microsoft.AspNet.WebApi" },
    { "*.csproj", "packages.config", "project.json" },
    "dotnet_dependency_detection"
  )

  -- Setup parser with .NET attribute patterns
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

  self.parser = annotation_parser:new(
    dotnet_annotation_patterns,
    dotnet_path_extraction_patterns,
    dotnet_method_mapping
  )
end

---Detects if .NET is present in the current project
function DotNetFramework:detect()
  return self.detector:is_target_detected()
end

---Parses .NET content to extract endpoint information
function DotNetFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parser:parse_content(content, file_path, line_number, column)

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
