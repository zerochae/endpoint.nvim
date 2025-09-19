local Parser = require "endpoint.core.Parser"

---@class endpoint.ExpressParser
local ExpressParser = setmetatable({}, { __index = Parser })
ExpressParser.__index = ExpressParser

-- ========================================
-- PUBLIC METHODS
-- ========================================

---Creates a new ExpressParser instance
function ExpressParser:new()
  local express_parser = Parser:new {
    parser_name = "express_parser",
    framework_name = "express",
    language = "javascript",
  }
  setmetatable(express_parser, self)
  return express_parser
end

---Extracts base path from Express router file
function ExpressParser:extract_base_path()
  -- Express doesn't have base path concept like Spring/Symfony
  return ""
end

---Extracts endpoint path from Express route content
function ExpressParser:extract_endpoint_path(content, file_path, line_number)
  -- Try standard app.method() or router.method() pattern
  local path = content:match "%w+%.%w+%(['\"]([^'\"]+)['\"]"
  if path then
    return path
  end

  -- Try destructured pattern: get('/path', ...)
  path = content:match "%w+%(['\"]([^'\"]+)['\"]"
  if path then
    return path
  end

  return nil
end

---Extracts HTTP method from Express route content
function ExpressParser:extract_method(content)
  -- Try standard app.method() or router.method() pattern
  local method = content:match "%w+%.(%w+)%("
  if method then
    local http_method = method:upper()
    return http_method
  end

  -- Try destructured pattern: get('/path', ...)
  local destructured_method = content:match "(%w+)%(['\"]"
  if destructured_method then
    local http_method = destructured_method:upper()
    -- Handle 'del' alias for DELETE
    if http_method == "DEL" then
      http_method = "DELETE"
    end
    return http_method
  end

  return "GET" -- Default fallback
end

---Override parse_content to add Express-specific metadata
function ExpressParser:parse_content(content, file_path, line_number, column)
  -- Call parent implementation
  local endpoint = Parser.parse_content(self, content, file_path, line_number, column)

  if endpoint then
    -- Add Express-specific tags and metadata
    endpoint.tags = { "javascript", "express", "route" }
    endpoint.metadata = self:create_metadata("route", {
      route_type = self:_detect_route_type(content),
      app_type = self:_extract_app_type(content),
    }, content)
  end

  return endpoint
end

---Validates if content contains Express route definitions
function ExpressParser:is_content_valid_for_parsing(content)
  if not Parser.is_content_valid_for_parsing(self, content) then
    return false
  end

  -- Check if content contains Express route patterns
  return self:_is_express_route_content(content)
end

---Gets parsing confidence for Express routes
function ExpressParser:get_parsing_confidence(content)
  if not self:is_content_valid_for_parsing(content) then
    return 0.0
  end

  local base_confidence = 0.85
  local confidence_boost = 0

  -- Boost for standard app/router patterns
  if content:match "app%.%w+%(" or content:match "router%.%w+%(" then
    confidence_boost = confidence_boost + 0.1
  end

  -- Boost for well-formed paths
  local path = self:extract_endpoint_path(content)
  if path and path:match "^/" then
    confidence_boost = confidence_boost + 0.05
  end

  return math.min(base_confidence + confidence_boost, 1.0)
end

-- ========================================
-- PRIVATE METHODS
-- ========================================

---Checks if content looks like Express route content
function ExpressParser:_is_express_route_content(content)
  -- Standard patterns: app.get(, router.post(, etc.
  if content:match "app%.%w+%(" or content:match "router%.%w+%(" then
    return true
  end

  -- Destructured patterns: get(, post(, etc.
  if content:match "%w+%(['\"]" then
    local method = content:match "(%w+)%(['\"]"
    if method then
      local http_method = method:lower()
      return http_method == "get"
        or http_method == "post"
        or http_method == "put"
        or http_method == "delete"
        or http_method == "del"
        or http_method == "patch"
    end
  end

  return false
end

---Detects the type of Express route (app vs router vs destructured)
function ExpressParser:_detect_route_type(content)
  if content:match "app%.%w+%(" then
    return "app_route"
  elseif content:match "router%.%w+%(" then
    return "router_route"
  elseif content:match "%w+%(['\"]" then
    return "destructured_route"
  else
    return "unknown"
  end
end

---Extracts the app type (app, router, or method name for destructured)
function ExpressParser:_extract_app_type(content)
  -- Standard patterns
  local app_type = content:match "(%w+)%.%w+%("
  if app_type then
    return app_type
  end

  -- Destructured patterns
  local method = content:match "(%w+)%(['\"]"
  if method then
    return "destructured_" .. method
  end

  return "unknown"
end

return ExpressParser

