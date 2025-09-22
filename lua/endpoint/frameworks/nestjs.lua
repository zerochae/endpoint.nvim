local Framework = require "endpoint.core.Framework"
local NestJsParser = require "endpoint.parser.nestjs_parser"

---@class endpoint.NestJsFramework
local NestJsFramework = setmetatable({}, { __index = Framework })
NestJsFramework.__index = NestJsFramework

---Creates a new NestJsFramework instance
function NestJsFramework:new()
  local nestjs_framework_instance = Framework.new(self, "nestjs", {
    file_extensions = { "*.ts", "*.js" },
    exclude_patterns = { "**/node_modules", "**/dist", "**/build" },
    patterns = {
      GET = { "@Get\\s*\\(", "@HttpCode.*@Get" },
      POST = { "@Post\\s*\\(", "@HttpCode.*@Post" },
      PUT = { "@Put\\s*\\(", "@HttpCode.*@Put" },
      DELETE = { "@Delete\\s*\\(", "@HttpCode.*@Delete" },
      PATCH = { "@Patch\\s*\\(", "@HttpCode.*@Patch" },
      OPTIONS = { "@Options\\s*\\(", "@HttpCode.*@Options" },
      HEAD = { "@Head\\s*\\(", "@HttpCode.*@Head" },
      QUERY = { "@Query\\s*\\(", "@Resolver.*@Query" },
      MUTATION = { "@Mutation\\s*\\(", "@Resolver.*@Mutation" },
    },
    search_options = { "--case-sensitive", "--type", "ts" },
    controller_extractors = {
      {
        pattern = "([^/]+)%.controller%.%w+$",
        transform = function(name)
          local pascal = name
            :gsub("%-(%w)", function(l)
              return l:upper()
            end)
            :gsub("^%w", string.upper)
          return pascal .. "Controller"
        end,
      },
      {
        pattern = "([^/]+)%.resolver%.%w+$",
        transform = function(name)
          local pascal = name
            :gsub("%-(%w)", function(l)
              return l:upper()
            end)
            :gsub("^%w", string.upper)
          return pascal .. "Resolver"
        end,
      },
      {
        pattern = "([^/]+)%.%w+$",
        transform = function(name)
          return name:gsub("Controller$", ""):gsub("Service$", ""):gsub("Resolver$", "")
        end,
      },
    },
    detector = {
      dependencies = { "@nestjs/core", "@nestjs/common", "nestjs" },
      manifest_files = { "package.json", "tsconfig.json", "nest-cli.json" },
      name = "nestjs_dependency_detection",
    },
    parser = NestJsParser,
  })
  setmetatable(nestjs_framework_instance, self)
  return nestjs_framework_instance
end

return NestJsFramework
