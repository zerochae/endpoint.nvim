-- NestJS Framework Module
local framework = require "endpoint.framework"

---@type endpoint.framework_base
return framework:new("nestjs"):setup {
  file_extensions = { "*.ts", "*.js" },
  exclude_patterns = { "**/node_modules/**", "**/dist/**" },
  detection = {
    dependencies = { "@nestjs/core", "@nestjs/common", "@nestjs" },
    manifest_files = { "package.json" },
  },
  type = "pattern",
  patterns = {
    GET = { "@Get", "@Controller" },
    POST = { "@Post", "@Controller" },
    PUT = { "@Put", "@Controller" },
    DELETE = { "@Delete", "@Controller" },
    PATCH = { "@Patch", "@Controller" },
    OPTIONS = { "@Options", "@Controller" },
    HEAD = { "@Head", "@Controller" },
  },
  parser = require "endpoint.frameworks.nestjs.parser",
}
