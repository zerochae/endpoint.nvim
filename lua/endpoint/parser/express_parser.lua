local Parser = require "endpoint.core.Parser"

---@class endpoint.ExpressParser
local ExpressParser = setmetatable({}, { __index = Parser })
ExpressParser.__index = ExpressParser

-- Pattern definitions for different file types
local js_patterns = {
  -- Content validation patterns
  app_methods = { "^[^/]*app%.get", "^[^/]*app%.post", "^[^/]*app%.put", "^[^/]*app%.delete", "^[^/]*app%.patch" },
  router_methods = { "^[^/]*router%.get", "^[^/]*router%.post", "^[^/]*router%.put", "^[^/]*router%.delete", "^[^/]*router%.patch" },
  destructured_methods = { "^%s*get%f[%W]%s*[<(]", "^%s*post%f[%W]%s*[<(]", "^%s*put%f[%W]%s*[<(]", "^%s*delete%f[%W]%s*[<(]", "^%s*del%f[%W]%s*[<(]", "^%s*patch%f[%W]%s*[<(]" },

  -- Method extraction patterns
  method_extract = {
    standard = "%w+%.(%w+)%f[%W]",
    destructured = "^%s*(%w+)%f[%W]%s*[<(]"
  },

  -- Path extraction patterns
  path_extract = {
    quoted = "['\"]([^'\"]+)['\"]"
  },

  -- Route type detection patterns
  route_type = {
    app = "app%.",
    router = "router%.",
    destructured = "^%s*%w+%s*%("
  }
}

local ts_patterns = {
  -- Content validation patterns
  app_methods = { "^[^/]*app%.get%s*<", "^[^/]*app%.post%s*<", "^[^/]*app%.put%s*<", "^[^/]*app%.delete%s*<", "^[^/]*app%.patch%s*<" },
  router_methods = { "^[^/]*router%.get%s*<", "^[^/]*router%.post%s*<", "^[^/]*router%.put%s*<", "^[^/]*router%.delete%s*<", "^[^/]*router%.patch%s*<" },
  destructured_methods = { "^%s*get%f[%W]%s*<", "^%s*post%f[%W]%s*<", "^%s*put%f[%W]%s*<", "^%s*delete%f[%W]%s*<", "^%s*del%f[%W]%s*<", "^%s*patch%f[%W]%s*<" },

  -- Method extraction patterns (same as JS since we use word boundaries)
  method_extract = {
    standard = "%w+%.(%w+)%f[%W]",
    destructured = "^%s*(%w+)%f[%W]%s*[<(]"
  },

  -- Path extraction patterns (same as JS)
  path_extract = {
    quoted = "['\"]([^'\"]+)['\"]"
  },

  -- Route type detection patterns
  route_type = {
    app = "app%.",
    router = "router%.",
    destructured = "^%s*%w+%f[%W]%s*[<(]"
  }
}

-- ========================================
-- PUBLIC METHODS
-- ========================================

---Creates a new ExpressParser instance
function ExpressParser:new()
  local express_parser = Parser:new {
    parser_name = "express_parser",
    framework_name = "express",
    language = "javascript",
    supported_languages = { "javascript", "typescript" },
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
  -- Use pattern from both JS and TS (they're the same for path extraction)
  local path = content:match(js_patterns.path_extract.quoted)
  if path and path:match "^/" then
    return path
  end

  return nil
end

---Extracts HTTP method from Express route content
function ExpressParser:extract_method(content)
  -- Try standard app.method() or router.method() pattern using JS patterns
  local method = content:match(js_patterns.method_extract.standard)
  if method then
    local http_method = method:upper()
    return http_method
  end

  -- Try destructured pattern using TS patterns (more comprehensive)
  local destructured_method = content:match(ts_patterns.method_extract.destructured)
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
  if content:match(js_patterns.route_type.app) or content:match(js_patterns.route_type.router) then
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
  -- Helper function to check patterns
  local function check_patterns(pattern_set)
    for _, patterns in pairs(pattern_set) do
      for _, pattern in ipairs(patterns) do
        if content:match(pattern) then
          return true
        end
      end
    end
    return false
  end

  -- Check JavaScript patterns (includes basic cases)
  if check_patterns(js_patterns) then
    return true
  end

  -- Check TypeScript patterns (includes generics)
  if check_patterns(ts_patterns) then
    return true
  end

  -- Check for multiline generic patterns (app.get< or router.get< at line start)
  if content:match("^[^/]*app%.%w+%s*<") or content:match("^[^/]*router%.%w+%s*<") then
    return true
  end

  -- Check for destructured multiline patterns
  if content:match("^%s*%w+%f[%W]%s*<") then
    local method = content:match("^%s*(%w+)%f[%W]%s*<")
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
  if content:match(js_patterns.route_type.app) then
    return "app_route"
  elseif content:match(js_patterns.route_type.router) then
    return "router_route"
  elseif content:match(ts_patterns.route_type.destructured) then
    return "destructured_route"
  else
    return "unknown"
  end
end

---Extracts the app type (app, router, or method name for destructured)
function ExpressParser:_extract_app_type(content)
  -- Standard patterns: app.method or router.method
  local app_type = content:match "(%w+)%."
  if app_type then
    return app_type
  end

  -- Destructured patterns using TS pattern (more comprehensive)
  local method = content:match(ts_patterns.method_extract.destructured)
  if method then
    return "destructured_" .. method
  end

  return "unknown"
end

return ExpressParser

