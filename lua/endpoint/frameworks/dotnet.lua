local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
local DotNetParser = require "endpoint.parser.dotnet_parser"

---@class endpoint.DotNetFramework
local DotNetFramework = setmetatable({}, { __index = Framework })
DotNetFramework.__index = DotNetFramework

---Creates a new DotNetFramework instance
function DotNetFramework:new()
  local dotnet_framework_instance = Framework.new(self, "dotnet", {
    file_extensions = { "*.cs" },
    exclude_patterns = { "**/bin", "**/obj", "**/packages" },
    patterns = {
      GET = { "\\[HttpGet", "\\[Route.*\\[HttpGet", "app\\.MapGet", "endpoints\\.MapGet", "\\.Get\\(" },
      POST = { "\\[HttpPost", "\\[Route.*\\[HttpPost", "app\\.MapPost", "endpoints\\.MapPost", "\\.Post\\(" },
      PUT = { "\\[HttpPut", "\\[Route.*\\[HttpPut", "app\\.MapPut", "endpoints\\.MapPut", "\\.Put\\(" },
      DELETE = { "\\[HttpDelete", "\\[Route.*\\[HttpDelete", "app\\.MapDelete", "endpoints\\.MapDelete", "\\.Delete\\(" },
      PATCH = { "\\[HttpPatch", "\\[Route.*\\[HttpPatch", "app\\.MapPatch", "endpoints\\.MapPatch", "\\.Patch\\(" },
    },
    search_options = { "--case-sensitive", "--type", "csharp" },
  })
  setmetatable(dotnet_framework_instance, self)
  return dotnet_framework_instance
end

---Sets up detection and parsing for .NET
function DotNetFramework:_initialize()
  -- Setup detector
  self.detector = DependencyDetector:new(
    { "Microsoft.AspNetCore", "Microsoft.AspNet.WebApi" },
    { "*.csproj", "*.sln", "global.json", "appsettings.json", "Program.cs", "Startup.cs" },
    "dotnet_dependency_detection"
  )

  -- Setup .NET-specific parser
  self.parser = DotNetParser:new()
end

---Extract controller name from .NET file path
function DotNetFramework:getControllerName(file_path)
  -- .NET: Controllers/UsersController.cs → UsersController
  local name = file_path:match "([^/]+)%.cs$"
  if name then
    return name
  end
  return nil
end

return DotNetFramework
