local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"

---@class endpoint.FrameworkRegistry : Class
local FrameworkRegistry = class('FrameworkRegistry')

function FrameworkRegistry:initialize()
  self.frameworks = {}
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