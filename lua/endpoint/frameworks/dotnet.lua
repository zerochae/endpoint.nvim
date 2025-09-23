local Framework = require "endpoint.core.Framework"
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
      GET = { "\\[Route\\(", "\\[HttpGet\\(", "app\\.MapGet", "endpoints\\.MapGet", "\\.Get\\(" },
      POST = { "\\[Route\\(", "\\[HttpPost\\(", "app\\.MapPost", "endpoints\\.MapPost", "\\.Post\\(" },
      PUT = { "\\[Route\\(", "\\[HttpPut\\(", "app\\.MapPut", "endpoints\\.MapPut", "\\.Put\\(" },
      DELETE = { "\\[Route\\(", "\\[HttpDelete\\(", "app\\.MapDelete", "endpoints\\.MapDelete", "\\.Delete\\(" },
      PATCH = { "\\[Route\\(", "\\[HttpPatch\\(", "app\\.MapPatch", "endpoints\\.MapPatch", "\\.Patch\\(" },
    },
    search_options = { "--case-sensitive", "--type", "csharp", "-U", "--multiline-dotall" },
    controller_extractors = {
      { pattern = "([^/]+)%.cs$" },
    },
    detector = {
      dependencies = { "Microsoft.AspNetCore", "Microsoft.AspNet.WebApi" },
      manifest_files = { "*.csproj", "*.sln", "global.json", "appsettings.json", "Program.cs", "Startup.cs" },
      name = "dotnet_dependency_detection",
    },
    parser = DotNetParser,
  })
  setmetatable(dotnet_framework_instance, self)
  return dotnet_framework_instance
end

return DotNetFramework
