---@class EventManager
---@field private event_listeners table<string, function[]>
local EventManager = {}
EventManager.__index = EventManager

local log = require "endpoint.utils.log"

---Creates a new EventManager instance
---@return EventManager
function EventManager:new()
  local event_manager_instance = setmetatable({}, self)
  event_manager_instance.event_listeners = {}
  return event_manager_instance
end

---Registers an event listener for a specific event type
---@param event_type string The type of event to listen for
---@param listener_callback function The callback function to execute when event occurs
---@param listener_priority? number Optional priority for listener execution order (higher = earlier)
function EventManager:add_event_listener(event_type, listener_callback, listener_priority)
  if type(listener_callback) ~= "function" then
    error("Event listener must be a function")
  end

  if not self.event_listeners[event_type] then
    self.event_listeners[event_type] = {}
  end

  local event_listener_entry = {
    callback_function = listener_callback,
    execution_priority = listener_priority or 0,
    registration_timestamp = vim.loop.hrtime()
  }

  table.insert(self.event_listeners[event_type], event_listener_entry)

  -- Sort listeners by priority (higher priority first)
  table.sort(self.event_listeners[event_type], function(listener_a, listener_b)
    return listener_a.execution_priority > listener_b.execution_priority
  end)

  log.framework_debug(string.format("Registered event listener for '%s' with priority %d",
    event_type, listener_priority or 0))
end

---Removes an event listener for a specific event type
---@param event_type string The type of event
---@param listener_callback function The callback function to remove
---@return boolean was_listener_removed True if listener was found and removed
function EventManager:remove_event_listener(event_type, listener_callback)
  if not self.event_listeners[event_type] then
    return false
  end

  for listener_index, event_listener_entry in ipairs(self.event_listeners[event_type]) do
    if event_listener_entry.callback_function == listener_callback then
      table.remove(self.event_listeners[event_type], listener_index)
      log.framework_debug(string.format("Removed event listener for '%s'", event_type))
      return true
    end
  end

  return false
end

---Emits an event to all registered listeners
---@param event_type string The type of event to emit
---@param event_data? table Optional data to pass to listeners
---@return table emission_results Results from all listener callbacks
function EventManager:emit_event(event_type, event_data)
  if not self.event_listeners[event_type] then
    log.framework_debug(string.format("No listeners registered for event '%s'", event_type))
    return {}
  end

  local emission_results = {}
  local event_data_payload = event_data or {}

  log.framework_debug(string.format("Emitting event '%s' to %d listeners",
    event_type, #self.event_listeners[event_type]))

  for listener_index, event_listener_entry in ipairs(self.event_listeners[event_type]) do
    local execution_success, listener_result = pcall(event_listener_entry.callback_function, event_data_payload)

    if execution_success then
      table.insert(emission_results, {
        listener_index = listener_index,
        execution_result = listener_result,
        execution_priority = event_listener_entry.execution_priority,
        execution_status = "success"
      })
    else
      log.framework_debug(string.format("Event listener %d for '%s' failed: %s",
        listener_index, event_type, listener_result))
      table.insert(emission_results, {
        listener_index = listener_index,
        execution_error = listener_result,
        execution_priority = event_listener_entry.execution_priority,
        execution_status = "error"
      })
    end
  end

  return emission_results
end

---Gets all registered event types
---@return string[] registered_event_types List of event types with registered listeners
function EventManager:get_registered_event_types()
  local registered_event_types = {}
  for event_type, _ in pairs(self.event_listeners) do
    table.insert(registered_event_types, event_type)
  end
  table.sort(registered_event_types)
  return registered_event_types
end

---Gets the number of listeners for a specific event type
---@param event_type string The event type to check
---@return number listener_count Number of registered listeners
function EventManager:get_listener_count(event_type)
  if not self.event_listeners[event_type] then
    return 0
  end
  return #self.event_listeners[event_type]
end

---Removes all listeners for a specific event type
---@param event_type string The event type to clear
---@return number removed_listener_count Number of listeners that were removed
function EventManager:clear_event_listeners(event_type)
  if not self.event_listeners[event_type] then
    return 0
  end

  local removed_listener_count = #self.event_listeners[event_type]
  self.event_listeners[event_type] = nil

  log.framework_debug(string.format("Cleared %d listeners for event '%s'",
    removed_listener_count, event_type))

  return removed_listener_count
end

---Removes all listeners for all event types
---@return number total_removed_listeners Total number of listeners removed
function EventManager:clear_all_event_listeners()
  local total_removed_listeners = 0

  for event_type, listener_list in pairs(self.event_listeners) do
    total_removed_listeners = total_removed_listeners + #listener_list
  end

  self.event_listeners = {}

  log.framework_debug(string.format("Cleared all %d event listeners", total_removed_listeners))

  return total_removed_listeners
end

-- Event type constants for commonly used events
EventManager.EVENT_TYPES = {
  FRAMEWORK_DETECTED = "framework_detected",
  ENDPOINT_DISCOVERED = "endpoint_discovered",
  SCAN_STARTED = "scan_started",
  SCAN_COMPLETED = "scan_completed",
  PARSING_ERROR = "parsing_error",
  DETECTION_ERROR = "detection_error",
  CACHE_UPDATED = "cache_updated",
  CONFIG_CHANGED = "config_changed"
}

return EventManager