local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"

---@class endpoint.FrameworkRegistry : Class
local FrameworkRegistry = class "FrameworkRegistry"

function FrameworkRegistry:initialize()
  self.frameworks = {}
  self:_register_default_frameworks()
end

function FrameworkRegistry:_register_default_frameworks()
  log.framework_debug "Registering all available frameworks"

  local SpringFramework = require "endpoint.frameworks.spring"
  local FastApiFramework = require "endpoint.frameworks.fastapi"
  local ExpressFramework = require "endpoint.frameworks.express"
  local RailsFramework = require "endpoint.frameworks.rails"
  local NestJsFramework = require "endpoint.frameworks.nestjs"
  local SymfonyFramework = require "endpoint.frameworks.symfony"
  local KtorFramework = require "endpoint.frameworks.ktor"
  local DotNetFramework = require "endpoint.frameworks.dotnet"
  local ServletFramework = require "endpoint.frameworks.servlet"
  local ReactRouterFramework = require "endpoint.frameworks.react_router"

  local framework_classes = {
    SpringFramework,
    RailsFramework,
    SymfonyFramework,
    ExpressFramework,
    NestJsFramework,
    FastApiFramework,
    DotNetFramework,
    KtorFramework,
    ServletFramework,
    ReactRouterFramework,
  }

  for _, framework_class in ipairs(framework_classes) do
    local framework_instance = framework_class:new()
    self:register(framework_instance)
  end

  log.framework_debug(string.format("Registered %d frameworks", #framework_classes))
end

function FrameworkRegistry:register(framework_instance)
  local framework_name = framework_instance:get_name()

  for _, existing_framework in ipairs(self.frameworks) do
    if existing_framework:get_name() == framework_name then
      log.framework_debug("Framework already registered: " .. framework_name)
      return
    end
  end

  table.insert(self.frameworks, framework_instance)
  log.framework_debug("Registered framework: " .. framework_name)
end

function FrameworkRegistry:unregister(framework_name)
  for index, framework in ipairs(self.frameworks) do
    if framework:get_name() == framework_name then
      table.remove(self.frameworks, index)
      log.framework_debug("Unregistered framework: " .. framework_name)
      return true
    end
  end
  return false
end

function FrameworkRegistry:get_all()
  return vim.deepcopy(self.frameworks)
end

function FrameworkRegistry:get_by_name(framework_name)
  for _, framework in ipairs(self.frameworks) do
    if framework:get_name() == framework_name then
      return framework
    end
  end
  return nil
end

function FrameworkRegistry:detect_all()
  local detected_frameworks = {}
  for _, framework in ipairs(self.frameworks) do
    if framework:detect() then
      table.insert(detected_frameworks, framework)
      log.framework_debug("Detected framework: " .. framework:get_name())
    end
  end
  return detected_frameworks
end

function FrameworkRegistry:clear()
  local count = #self.frameworks
  self.frameworks = {}
  log.framework_debug(string.format("Cleared %d frameworks", count))
  return count
end

function FrameworkRegistry:get_info()
  local info_list = {}
  for _, framework in ipairs(self.frameworks) do
    table.insert(info_list, {
      name = framework:get_name(),
      detected = framework:detect(),
      config = framework:get_config(),
    })
  end
  return info_list
end

return FrameworkRegistry
