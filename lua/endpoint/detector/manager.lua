local base_manager = require "endpoint.core.base_manager"

local M = base_manager.create_manager("detector", "framework")

-- Detector implementations will be registered during setup
-- Temporary fallback: register immediately for compatibility
M.register("framework", "endpoint.detector.registry.framework")
M.register("picker", "endpoint.detector.registry.picker")

-- Detector-specific methods
function M.detect_by_type(detector_type, ...)
  local detector = M.get(detector_type)
  if not detector then
    return nil
  end

  return detector:detect(...)
end

function M.detect_all_available(detector_type)
  local detector = M.get(detector_type)
  if not detector then
    return {}
  end

  if detector.get_available then
    return detector:get_available()
  end

  return {}
end

return M

