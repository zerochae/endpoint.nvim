local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"
local EventBus = require "endpoint.core.EventBus"
local FrameworkRegistry = require "endpoint.core.FrameworkRegistry"
local CacheManager = require "endpoint.manager.CacheManager"
local config = require "endpoint.config"
local PickerManager = require "endpoint.manager.PickerManager"

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

---@class endpoint.EndpointManager
local EndpointManager = class('EndpointManager')

function EndpointManager:initialize(dependencies)
  dependencies = dependencies or {}

  self.framework_registry = dependencies.framework_registry or FrameworkRegistry:new()
  self.cache_manager = dependencies.cache_manager or CacheManager:new()
  self.picker_manager = dependencies.picker_manager or PickerManager:new()
  self._initialized = false
end

function EndpointManager:get_event_manager()
  return EventBus.get_instance()
end

---Setup the endpoint manager with configuration and register all frameworks
function EndpointManager:setup(user_config)
  config.setup(user_config)
  self:register_all_frameworks()
  self._initialized = true
end

---Ensures the endpoint manager is initialized
function EndpointManager:_ensure_initialized()
  if not self._initialized then
    error "endpoint.nvim not initialized. Call setup() first."
  end
end

---Registers all available frameworks with the endpoint manager
function EndpointManager:register_all_frameworks()
  log.framework_debug "Registering all available frameworks"

  -- Create framework instances from classes
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
    -- FlaskFramework,
    -- DjangoFramework,
    -- GinFramework,
    -- AxumFramework,
    -- PhoenixFramework,
  }

  for _, framework_class in ipairs(framework_classes) do
    local framework_instance = framework_class:new()
    self:register_framework(framework_instance)
  end

  log.framework_debug(string.format("Registered %d frameworks", #framework_classes))
end

---Registers a framework with the endpoint manager
function EndpointManager:register_framework(framework_instance)
  if not framework_instance or not framework_instance.get_name then
    error "Invalid framework instance provided"
  end

  self.framework_registry:register(framework_instance)

  local EventManager = require "endpoint.manager.EventManager"
  self:get_event_manager():emit_event(EventManager.EVENT_TYPES.FRAMEWORK_DETECTED, {
    framework_name = framework_instance:get_name(),
    framework_instance = framework_instance,
  })
end

---Unregisters a framework from the endpoint manager
function EndpointManager:unregister_framework(framework_name)
  return self.framework_registry:unregister(framework_name)
end

---Gets all registered frameworks
function EndpointManager:get_registered_frameworks()
  return self.framework_registry:get_all()
end

---Detects which frameworks are present in the current project
function EndpointManager:detect_project_frameworks()
  return self.framework_registry:detect_all()
end

---Scans for endpoints using all detected frameworks
function EndpointManager:scan_all_endpoints(scan_options)
  scan_options = scan_options or {}

  local EventManager = require "endpoint.manager.EventManager"
  local event_manager = self:get_event_manager()

  event_manager:emit_event(EventManager.EVENT_TYPES.SCAN_STARTED, {
    scan_options = scan_options,
    registered_framework_count = #self.framework_registry:get_all(),
  })

  local all_discovered_endpoints = {}
  local detected_frameworks = self:detect_project_frameworks()

  if #detected_frameworks == 0 then
    log.framework_debug "No frameworks detected in project"
    return all_discovered_endpoints
  end

  log.framework_debug(string.format("Scanning with %d detected frameworks", #detected_frameworks))

  for _, framework_instance in ipairs(detected_frameworks) do
    local framework_name = framework_instance:get_name()
    log.framework_debug("Scanning endpoints with framework: " .. framework_name)

    local framework_endpoints = framework_instance:scan(scan_options)

    for _, discovered_endpoint in ipairs(framework_endpoints) do
      event_manager:emit_event(EventManager.EVENT_TYPES.ENDPOINT_DISCOVERED, {
        endpoint = discovered_endpoint,
        framework_name = framework_name,
      })

      table.insert(all_discovered_endpoints, discovered_endpoint)
    end

    log.framework_debug(string.format("Found %d endpoints with %s", #framework_endpoints, framework_name))
  end

  event_manager:emit_event(EventManager.EVENT_TYPES.SCAN_COMPLETED, {
    total_endpoints_found = #all_discovered_endpoints,
    frameworks_used = detected_frameworks,
  })

  log.framework_debug(string.format("Total endpoints discovered: %d", #all_discovered_endpoints))

  return all_discovered_endpoints
end

---Scans for endpoints using a specific framework
function EndpointManager:scan_with_framework(framework_name, scan_options)
  scan_options = scan_options or {}

  local target_framework = self.framework_registry:get_by_name(framework_name)

  if not target_framework then
    log.framework_debug("Framework not found: " .. framework_name)
    return {}
  end

  if not target_framework:detect() then
    log.framework_debug("Framework not detected in project: " .. framework_name)
    return {}
  end

  log.framework_debug("Scanning with specific framework: " .. framework_name)
  return target_framework:scan(scan_options)
end

---Adds an event listener for endpoint management events
function EndpointManager:add_event_listener(event_type, listener_callback, listener_priority)
  self:get_event_manager():add_event_listener(event_type, listener_callback, listener_priority)
end

---Removes an event listener
function EndpointManager:remove_event_listener(event_type, listener_callback)
  return self:get_event_manager():remove_event_listener(event_type, listener_callback)
end

---Gets information about all registered frameworks
function EndpointManager:get_framework_info()
  return self.framework_registry:get_info()
end

---Clears all registered frameworks
function EndpointManager:clear_all_frameworks()
  return self.framework_registry:clear()
end

---Main function to find and show endpoints with UI
function EndpointManager:find(opts)
  self:_ensure_initialized()
  opts = opts or {}

  local endpoints = self:_resolve_endpoints(opts)

  if #endpoints == 0 then
    local method_msg = opts.method and (" " .. opts.method) or ""
    vim.notify("No" .. method_msg .. " endpoints found", vim.log.levels.INFO)
    return
  end

  self:_show_with_picker(endpoints, opts)
end

---Resolves endpoints from cache or by scanning
---@private
function EndpointManager:_resolve_endpoints(opts)
  if not opts.force_refresh and self:_should_use_cache(opts.method) then
    return self.cache_manager:get_endpoints(opts.method)
  end

  local endpoints = self:scan_all_endpoints(opts)
  self:_update_cache_if_enabled(endpoints, opts.method)

  return endpoints
end

---Checks if cache should be used
---@private
function EndpointManager:_should_use_cache(method)
  local cache_config = config.get().cache
  if cache_config.mode == "none" then
    return false
  end

  if self.cache_manager then
    self.cache_manager:set_mode(cache_config.mode)
    return self.cache_manager:is_valid(method)
  end

  return false
end

---Updates cache if caching is enabled
---@private
function EndpointManager:_update_cache_if_enabled(endpoints, method)
  local cache_config = config.get().cache
  if cache_config.mode ~= "none" and self.cache_manager then
    self.cache_manager:set_mode(cache_config.mode)
    self.cache_manager:save_endpoints(endpoints, method)
  end
end

-- Legacy _handle_cache function - now integrated into find()
-- function EndpointManager:_handle_cache(endpoints, opts) ... end

---Shows endpoints using the configured picker
function EndpointManager:_show_with_picker(endpoints, opts)
  local picker_config = config.get()
  local picker_name = picker_config.picker and picker_config.picker.type or picker_config.picker or "vim_ui_select"

  local picker_instance, selected_picker_name = self.picker_manager:get_best_available_picker(picker_name)

  if selected_picker_name ~= picker_name then
    vim.notify(
      string.format(
        "Picker '%s' not available. Using fallback '%s'. Please install the required dependency or set picker.type explicitly in your config.",
        picker_name,
        selected_picker_name
      ),
      vim.log.levels.WARN
    )
  end

  local picker_configuration = picker_config.picker or {}
  local all_picker_opts = picker_configuration.options or picker_config.picker_opts or {}
  local current_picker_opts = all_picker_opts[selected_picker_name] or {}

  local user_picker_opts = (opts.picker_opts and opts.picker_opts[selected_picker_name]) or opts.picker_opts or {}
  local picker_opts = vim.tbl_deep_extend("force", current_picker_opts, user_picker_opts)

  picker_instance:show(endpoints, picker_opts)
end

---Clears the endpoint cache
function EndpointManager:clear_cache()
  self:_ensure_initialized()

  if self.cache_manager then
    self.cache_manager:clear()
    vim.notify("Cache cleared", vim.log.levels.INFO)
  else
    vim.notify("Cache not available", vim.log.levels.WARN)
  end
end

---Shows cache statistics
function EndpointManager:show_cache_stats()
  self:_ensure_initialized()

  if self.cache_manager then
    local stats = self.cache_manager:get_stats()
    local message =
      string.format("Cache: %d endpoints, valid: %s", stats.total_endpoints, stats.valid and "yes" or "no")
    vim.notify(message, vim.log.levels.INFO)
  else
    vim.notify("Cache not available", vim.log.levels.WARN)
  end
end

return EndpointManager
