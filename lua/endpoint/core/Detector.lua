---@class endpoint.Detector
local Detector = {}
Detector.__index = Detector

---Creates a new Detector instance with optional fields
function Detector:new(detection_name, fields)
  local detector_instance = setmetatable({}, self)
  detector_instance.detection_name = detection_name or "unknown"

  -- Set additional fields if provided
  if fields then
    for key, value in pairs(fields) do
      detector_instance[key] = value
    end
  end

  return detector_instance
end

---Detects if the target is present in the current environment
function Detector:is_target_detected()
  error("is_target_detected() must be implemented by subclass: " .. self.detection_name)
end

---Gets the name of this detector
function Detector:get_name()
  return self.detection_name
end

---Gets detailed information about what was detected
function Detector:get_detection_details()
  if not self:is_target_detected() then
    return nil
  end

  return {
    detector_name = self.detection_name,
    detected_at = os.time(),
    is_detected = true
  }
end

return Detector
