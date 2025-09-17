---@class FrameworkRegistry
---@field private endpoint_manager EndpointManager
local FrameworkRegistry = {}
FrameworkRegistry.__index = FrameworkRegistry

local EndpointManager = require "endpoint.core.EndpointManager"
local log = require "endpoint.utils.log"

-- Import all framework classes
local SpringFramework = require "endpoint.frameworks.spring"
local FastApiFramework = require "endpoint.frameworks.fastapi"
local ExpressFramework = require "endpoint.frameworks.express"
local FlaskFramework = require "endpoint.frameworks.flask"
local RailsFramework = require "endpoint.frameworks.rails"
local NestJsFramework = require "endpoint.frameworks.nestjs"
local DjangoFramework = require "endpoint.frameworks.django"
local GinFramework = require "endpoint.frameworks.gin"
local SymfonyFramework = require "endpoint.frameworks.symfony"
local KtorFramework = require "endpoint.frameworks.ktor"
local AxumFramework = require "endpoint.frameworks.axum"
local PhoenixFramework = require "endpoint.frameworks.phoenix"
local DotNetFramework = require "endpoint.frameworks.dotnet"

---Creates a new FrameworkRegistry instance
---@return FrameworkRegistry
function FrameworkRegistry:new()
  local framework_registry_instance = setmetatable({}, self)
  framework_registry_instance.endpoint_manager = EndpointManager:new()
  return framework_registry_instance
end

---Registers all available frameworks with the endpoint manager
function FrameworkRegistry:register_all_frameworks()
  log.framework_debug("Registering all available frameworks")

  -- Register all framework instances
  local framework_classes = {
    SpringFramework,
    FastApiFramework,
    ExpressFramework,
    FlaskFramework,
    RailsFramework,
    NestJsFramework,
    DjangoFramework,
    GinFramework,
    SymfonyFramework,
    KtorFramework,
    AxumFramework,
    PhoenixFramework,
    DotNetFramework,
  }

  for _, framework_class in ipairs(framework_classes) do
    local framework_instance = framework_class:new()
    self.endpoint_manager:register_framework(framework_instance)
  end

  log.framework_debug(string.format("Registered %d frameworks", #framework_classes))
end

---Gets the endpoint manager instance
---@return EndpointManager endpoint_manager The endpoint manager instance
function FrameworkRegistry:get_endpoint_manager()
  return self.endpoint_manager
end

---Scans for endpoints using all registered frameworks
---@param scan_options? table Optional scan configuration
---@return endpoint.entry[] discovered_endpoints List of all discovered endpoints
function FrameworkRegistry:scan_all_endpoints(scan_options)
  return self.endpoint_manager:scan_all_endpoints(scan_options)
end

---Scans for endpoints using a specific framework
---@param framework_name string The name of the framework to use
---@param scan_options? table Optional scan configuration
---@return endpoint.entry[] discovered_endpoints List of discovered endpoints
function FrameworkRegistry:scan_with_framework(framework_name, scan_options)
  return self.endpoint_manager:scan_with_framework(framework_name, scan_options)
end

---Gets information about all registered frameworks
---@return table[] framework_info_list List of framework information
function FrameworkRegistry:get_framework_info()
  return self.endpoint_manager:get_framework_info()
end

---Detects which frameworks are present in the current project
---@return Framework[] detected_frameworks List of detected framework instances
function FrameworkRegistry:detect_project_frameworks()
  return self.endpoint_manager:detect_project_frameworks()
end

return FrameworkRegistry