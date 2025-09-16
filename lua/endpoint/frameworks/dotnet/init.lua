-- .NET Framework Module
local framework = require "endpoint.framework"

---@type endpoint.framework_base
return framework:new("dotnet"):setup {
  file_extensions = { "*.cs" },
  exclude_patterns = { "**/bin/**", "**/obj/**" },
  detection = {
    files = { "Program.cs", "Startup.cs" },
    dependencies = { "Microsoft.AspNetCore" },
    manifest_files = { "*.csproj" },
  },
  type = "pattern",
  patterns = {
    GET = { "\\[HttpGet", "\\[Route.*\\[HttpGet", "app\\.MapGet", "endpoints\\.MapGet", "\\.Get\\(" },
    POST = { "\\[HttpPost", "\\[Route.*\\[HttpPost", "app\\.MapPost", "endpoints\\.MapPost", "\\.Post\\(" },
    PUT = { "\\[HttpPut", "\\[Route.*\\[HttpPut", "app\\.MapPut", "endpoints\\.MapPut", "\\.Put\\(" },
    DELETE = { "\\[HttpDelete", "\\[Route.*\\[HttpDelete", "app\\.MapDelete", "endpoints\\.MapDelete", "\\.Delete\\(" },
    PATCH = { "\\[HttpPatch", "\\[Route.*\\[HttpPatch", "app\\.MapPatch", "endpoints\\.MapPatch", "\\.Patch\\(" },
  },
  parser = require "endpoint.frameworks.dotnet.parser",
}