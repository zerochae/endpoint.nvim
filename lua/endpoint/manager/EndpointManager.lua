---@class endpoint.EndpointManager
local EndpointManager = {}
EndpointManager.__index = EndpointManager

local log = require "endpoint.utils.log"
local EventManager = require "endpoint.manager.EventManager"
local CacheManager = require "endpoint.manager.CacheManager"
local config = require "endpoint.config"
local PickerManager = require "endpoint.manager.PickerManager"

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
local ServletFramework = require "endpoint.frameworks.servlet"
local ReactRouterFramework = require "endpoint.frameworks.react_router"

---Creates a new EndpointManager instance
function EndpointManager:new()
  local endpoint_manager_instance = setmetatable({}, self)
  endpoint_manager_instance.registered_frameworks = {}
  endpoint_manager_instance.event_manager = EventManager:new()
  endpoint_manager_instance.cache_manager = CacheManager:new()
  endpoint_manager_instance.picker_manager = PickerManager:new()
  endpoint_manager_instance._initialized = false
  return endpoint_manager_instance
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
    error("endpoint.nvim not initialized. Call setup() first.")
  end
end

---Registers all available frameworks with the endpoint manager
function EndpointManager:register_all_frameworks()
  log.framework_debug("Registering all available frameworks")

  -- Register all framework instances
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

  local framework_name = framework_instance:get_name()

  -- Check if framework is already registered
  for _, existing_framework in ipairs(self.registered_frameworks) do
    if existing_framework:get_name() == framework_name then
      log.framework_debug("Framework already registered: " .. framework_name)
      return
    end
  end

  table.insert(self.registered_frameworks, framework_instance)
  log.framework_debug("Registered framework: " .. framework_name)

  -- Emit framework registration event
  self.event_manager:emit_event(EventManager.EVENT_TYPES.FRAMEWORK_DETECTED, {
    framework_name = framework_name,
    framework_instance = framework_instance,
  })
end

---Unregisters a framework from the endpoint manager
function EndpointManager:unregister_framework(framework_name)
  for framework_index, registered_framework in ipairs(self.registered_frameworks) do
    if registered_framework:get_name() == framework_name then
      table.remove(self.registered_frameworks, framework_index)
      log.framework_debug("Unregistered framework: " .. framework_name)
      return true
    end
  end
  return false
end

---Gets all registered frameworks
function EndpointManager:get_registered_frameworks()
  return vim.deepcopy(self.registered_frameworks)
end

---Detects which frameworks are present in the current project
function EndpointManager:detect_project_frameworks()
  local detected_frameworks = {}

  for _, framework_instance in ipairs(self.registered_frameworks) do
    local framework_name = framework_instance:get_name()
    log.framework_debug("Checking framework detection: " .. framework_name)

    if framework_instance:detect() then
      table.insert(detected_frameworks, framework_instance)
      log.framework_debug("Framework detected: " .. framework_name)
    else
      log.framework_debug("Framework not detected: " .. framework_name)
    end
  end

  return detected_frameworks
end

---Scans for endpoints using all detected frameworks
function EndpointManager:scan_all_endpoints(scan_options)
  scan_options = scan_options or {}

  -- Emit scan started event
  self.event_manager:emit_event(EventManager.EVENT_TYPES.SCAN_STARTED, {
    scan_options = scan_options,
    registered_framework_count = #self.registered_frameworks,
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
      -- Emit endpoint discovery event
      self.event_manager:emit_event(EventManager.EVENT_TYPES.ENDPOINT_DISCOVERED, {
        endpoint = discovered_endpoint,
        framework_name = framework_name,
      })

      table.insert(all_discovered_endpoints, discovered_endpoint)
    end

    log.framework_debug(string.format("Found %d endpoints with %s", #framework_endpoints, framework_name))
  end

  -- Emit scan completed event
  self.event_manager:emit_event(EventManager.EVENT_TYPES.SCAN_COMPLETED, {
    total_endpoints_found = #all_discovered_endpoints,
    frameworks_used = detected_frameworks,
  })

  log.framework_debug(string.format("Total endpoints discovered: %d", #all_discovered_endpoints))

  return all_discovered_endpoints
end

---Scans for endpoints using a specific framework
function EndpointManager:scan_with_framework(framework_name, scan_options)
  scan_options = scan_options or {}

  local target_framework = nil
  for _, framework_instance in ipairs(self.registered_frameworks) do
    if framework_instance:get_name() == framework_name then
      target_framework = framework_instance
      break
    end
  end

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

---Gets the event manager instance for external event handling
function EndpointManager:get_event_manager()
  return self.event_manager
end

---Adds an event listener for endpoint management events
function EndpointManager:add_event_listener(event_type, listener_callback, listener_priority)
  self.event_manager:add_event_listener(event_type, listener_callback, listener_priority)
end

---Removes an event listener
function EndpointManager:remove_event_listener(event_type, listener_callback)
  return self.event_manager:remove_event_listener(event_type, listener_callback)
end

---Gets information about all registered frameworks
function EndpointManager:get_framework_info()
  local framework_info_list = {}

  for _, framework_instance in ipairs(self.registered_frameworks) do
    local framework_config = framework_instance:get_config()
    local is_framework_detected = framework_instance:detect()

    table.insert(framework_info_list, {
      name = framework_instance:get_name(),
      detected = is_framework_detected,
      file_extensions = framework_config.file_extensions,
      exclude_patterns = framework_config.exclude_patterns,
      pattern_count = framework_config.patterns and #vim.tbl_keys(framework_config.patterns) or 0,
    })
  end

  return framework_info_list
end

---Clears all registered frameworks
function EndpointManager:clear_all_frameworks()
  local removed_framework_count = #self.registered_frameworks
  self.registered_frameworks = {}

  log.framework_debug(string.format("Cleared %d registered frameworks", removed_framework_count))

  return removed_framework_count
end

---Main function to find and show endpoints with UI
function EndpointManager:find(opts)
  self:_ensure_initialized()
  opts = opts or {}

  local endpoints = self:scan_all_endpoints(opts)

  if #endpoints == 0 then
    vim.notify("No endpoints found", vim.log.levels.INFO)
    return
  end

  endpoints = self:_handle_cache(endpoints, opts)
  self:_show_with_picker(endpoints, opts)
end

---Handles caching logic for endpoints
function EndpointManager:_handle_cache(endpoints, opts)
  if opts.force_refresh then
    return endpoints
  end

  if self.cache_manager and self.cache_manager:is_valid() then
    return self.cache_manager:get_endpoints()
  else
    if self.cache_manager then
      self.cache_manager:save_endpoints(endpoints)
    end
    return endpoints
  end
end

---Shows endpoints using the configured picker
function EndpointManager:_show_with_picker(endpoints, opts)
  local picker_config = config.get()
  local picker_name = picker_config.picker and picker_config.picker.type or picker_config.picker or "telescope"

  local picker_instance, selected_picker_name = self.picker_manager:get_best_available_picker(picker_name)

  if selected_picker_name ~= picker_name then
    vim.notify("Picker '" .. picker_name .. "' not available, using " .. selected_picker_name, vim.log.levels.WARN)
  end

  local picker_configuration = picker_config.picker or {}
  local all_picker_opts = picker_configuration.options or picker_config.picker_opts or {}
  local current_picker_opts = all_picker_opts[selected_picker_name] or {}

  local user_picker_opts = (opts.picker_opts and opts.picker_opts[selected_picker_name]) or opts.picker_opts or {}
  local picker_opts = vim.tbl_deep_extend("force", current_picker_opts, user_picker_opts)

  picker_instance.show(endpoints, picker_opts)
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
    local message = string.format("Cache: %d endpoints, valid: %s", stats.total_endpoints, stats.valid and "yes" or "no")
    vim.notify(message, vim.log.levels.INFO)
  else
    vim.notify("Cache not available", vim.log.levels.WARN)
  end
end

return EndpointManager

