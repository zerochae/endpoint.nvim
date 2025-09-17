---@class EndpointManager
---@field private registered_frameworks Framework[]
---@field private event_manager EventManager
---@field private cache_manager any
local EndpointManager = {}
EndpointManager.__index = EndpointManager

local log = require "endpoint.utils.log"
local EventManager = require "endpoint.core.EventManager"

---Creates a new EndpointManager instance
---@return EndpointManager
function EndpointManager:new()
  local endpoint_manager_instance = setmetatable({}, self)
  endpoint_manager_instance.registered_frameworks = {}
  endpoint_manager_instance.event_manager = EventManager:new()
  endpoint_manager_instance.cache_manager = require "endpoint.cache"
  return endpoint_manager_instance
end

---Registers a framework with the endpoint manager
---@param framework_instance Framework The framework instance to register
function EndpointManager:register_framework(framework_instance)
  if not framework_instance or not framework_instance.get_name then
    error("Invalid framework instance provided")
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
    framework_instance = framework_instance
  })
end

---Unregisters a framework from the endpoint manager
---@param framework_name string The name of the framework to unregister
---@return boolean was_framework_removed True if framework was found and removed
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
---@return Framework[] registered_frameworks List of registered framework instances
function EndpointManager:get_registered_frameworks()
  return vim.deepcopy(self.registered_frameworks)
end

---Detects which frameworks are present in the current project
---@return Framework[] detected_frameworks List of detected framework instances
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
---@param scan_options? table Optional scan configuration
---@return endpoint.entry[] discovered_endpoints List of all discovered endpoints
function EndpointManager:scan_all_endpoints(scan_options)
  scan_options = scan_options or {}

  -- Emit scan started event
  self.event_manager:emit_event(EventManager.EVENT_TYPES.SCAN_STARTED, {
    scan_options = scan_options,
    registered_framework_count = #self.registered_frameworks
  })

  local all_discovered_endpoints = {}
  local detected_frameworks = self:detect_project_frameworks()

  if #detected_frameworks == 0 then
    log.framework_debug("No frameworks detected in project")
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
        framework_name = framework_name
      })

      table.insert(all_discovered_endpoints, discovered_endpoint)
    end

    log.framework_debug(string.format("Found %d endpoints with %s", #framework_endpoints, framework_name))
  end

  -- Emit scan completed event
  self.event_manager:emit_event(EventManager.EVENT_TYPES.SCAN_COMPLETED, {
    total_endpoints_found = #all_discovered_endpoints,
    frameworks_used = detected_frameworks
  })

  log.framework_debug(string.format("Total endpoints discovered: %d", #all_discovered_endpoints))

  return all_discovered_endpoints
end

---Scans for endpoints using a specific framework
---@param framework_name string The name of the framework to use
---@param scan_options? table Optional scan configuration
---@return endpoint.entry[] discovered_endpoints List of discovered endpoints
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
---@return EventManager event_manager The event manager instance
function EndpointManager:get_event_manager()
  return self.event_manager
end

---Adds an event listener for endpoint management events
---@param event_type string The type of event to listen for
---@param listener_callback function The callback function to execute
---@param listener_priority? number Optional priority for listener execution order
function EndpointManager:add_event_listener(event_type, listener_callback, listener_priority)
  self.event_manager:add_event_listener(event_type, listener_callback, listener_priority)
end

---Removes an event listener
---@param event_type string The type of event
---@param listener_callback function The callback function to remove
---@return boolean was_listener_removed True if listener was found and removed
function EndpointManager:remove_event_listener(event_type, listener_callback)
  return self.event_manager:remove_event_listener(event_type, listener_callback)
end

---Gets information about all registered frameworks
---@return table[] framework_info_list List of framework information
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
      pattern_count = framework_config.patterns and #vim.tbl_keys(framework_config.patterns) or 0
    })
  end

  return framework_info_list
end

---Clears all registered frameworks
---@return number removed_framework_count Number of frameworks that were removed
function EndpointManager:clear_all_frameworks()
  local removed_framework_count = #self.registered_frameworks
  self.registered_frameworks = {}

  log.framework_debug(string.format("Cleared %d registered frameworks", removed_framework_count))

  return removed_framework_count
end

return EndpointManager