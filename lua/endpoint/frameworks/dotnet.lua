local Framework = require "endpoint.core.Framework"
local DotNetParser = require "endpoint.parser.dotnet_parser"

---@class endpoint.DotNetFramework
local DotNetFramework = Framework:extend()

---Creates a new DotNetFramework instance
function DotNetFramework:new()
  DotNetFramework.super.new(self, {
    name = "dotnet",
    config = {
      file_extensions = { "*.cs" },
      exclude_patterns = { "**/bin", "**/obj", "**/packages" },
      patterns = {
        GET = { "\\[HttpGet\\]", "\\[HttpGet\\(", "app\\.MapGet", "endpoints\\.MapGet", "\\.Get\\(" },
        POST = { "\\[HttpPost\\]", "\\[HttpPost\\(", "app\\.MapPost", "endpoints\\.MapPost", "\\.Post\\(" },
        PUT = { "\\[HttpPut\\]", "\\[HttpPut\\(", "app\\.MapPut", "endpoints\\.MapPut", "\\.Put\\(" },
        DELETE = { "\\[HttpDelete\\]", "\\[HttpDelete\\(", "app\\.MapDelete", "endpoints\\.MapDelete", "\\.Delete\\(" },
        PATCH = { "\\[HttpPatch\\]", "\\[HttpPatch\\(", "app\\.MapPatch", "endpoints\\.MapPatch", "\\.Patch\\(" },
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
    },
  })
end

return DotNetFramework
