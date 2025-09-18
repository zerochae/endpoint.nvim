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
      GET = { "@Get\\(", "@HttpCode.-@Get" },
      POST = { "@Post\\(", "@HttpCode.-@Post" },
      PUT = { "@Put\\(", "@HttpCode.-@Put" },
      DELETE = { "@Delete\\(", "@HttpCode.-@Delete" },
      PATCH = { "@Patch\\(", "@HttpCode.-@Patch" },
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
        pattern = "([^/]+)%.%w+$",
        transform = function(name)
          return name:gsub("Controller$", ""):gsub("Service$", "")
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
