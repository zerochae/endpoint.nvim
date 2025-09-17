---@class endpoint.DetectionStrategy
local DetectionStrategy = {}
DetectionStrategy.__index = DetectionStrategy

---Creates a new DetectionStrategy instance
function DetectionStrategy:new(detection_name)
  local detection_strategy_instance = setmetatable({}, self)
  detection_strategy_instance.detection_name = detection_name or "unknown"
  return detection_strategy_instance
end

---Detects if the target is present in the current environment
function DetectionStrategy:is_target_detected()
  error("is_target_detected() must be implemented by subclass: " .. self.detection_name)
end

---Gets the name of this detection strategy
function DetectionStrategy:get_strategy_name()
  return self.detection_name
end

---Gets detailed information about what was detected
function DetectionStrategy:get_detection_details()
  if not self:is_target_detected() then
    return nil
  end

  return {
    strategy_name = self.detection_name,
    detected_at = os.time(),
    is_detected = true
  }
end

return DetectionStrategy
