local Parser = require "endpoint.core.Parser"

---@class endpoint.NestJsParser
local NestJsParser = setmetatable({}, { __index = Parser })
NestJsParser.__index = NestJsParser

-- ========================================
-- PUBLIC METHODS
-- ========================================

---Creates a new NestJsParser instance
function NestJsParser:new()
  local nestjs_parser = Parser:new {
    parser_name = "nestjs_parser",
    framework_name = "nestjs",
    language = "typescript",
  }
  setmetatable(nestjs_parser, self)
  return nestjs_parser
end

---Extracts base path from NestJS controller file
function NestJsParser:extract_base_path(file_path)
  return self:_get_controller_path(file_path)
end

---Extracts endpoint path from NestJS decorator content
function NestJsParser:extract_endpoint_path(content)
  -- @Get('path'), @Post("path"), etc.
  local path = content:match "@%w+%s*%(%s*[\"']([^\"']+)[\"']"
  if path then
    -- Ensure path starts with /
    if not path:match "^/" then
      return "/" .. path
    end
    return path
  end

  -- @Get() without parameter - root path
  local decorator_match = content:match "@(%w+)%s*%(%s*%)"
  if decorator_match and not self:_is_controller_decorator(content) then
    return "/" -- Root path for this controller
  end

  return nil
end

---Extracts HTTP method from NestJS decorator content
function NestJsParser:extract_method(content)
  -- Extract from decorator
  local method = content:match "@(%w+)%s*%("
  if method and not self:_is_controller_decorator(content) then
    return method:upper()
  end

  return "GET" -- Default fallback
end

---Parses NestJS line and returns array of endpoints
function NestJsParser:parse_line_to_endpoints(content, file_path, line_number, column)
  -- Only process if this looks like NestJS decorator
  if not self:is_content_valid_for_parsing(content) then
    return {}
  end

  -- Skip @Controller decorators
  if self:_is_controller_decorator(content) then
    return {}
  end

  -- Extract path and method
  local endpoint_path = self:extract_endpoint_path(content)
  if not endpoint_path then
    return {}
  end

  local method = self:extract_method(content)
  if not method then
    return {}
  end

  -- Get base path and combine
  local base_path = self:extract_base_path(file_path, line_number)
  local full_path = self:_combine_paths(base_path, endpoint_path)

  -- Create single endpoint
  local endpoint = {
    method = method:upper(),
    endpoint_path = full_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = method:upper() .. " " .. full_path,
    confidence = self:get_parsing_confidence(content),
    tags = { "typescript", "nestjs", "decorator" },
    metadata = self:create_metadata("decorator", {
      decorator_type = self:_extract_decorator_type(content),
      has_http_code = self:_has_http_code_decorator(content),
    }, content),
  }

  return { endpoint }
end

---Validates if content contains NestJS decorators
function NestJsParser:is_content_valid_for_parsing(content)
  if not Parser.is_content_valid_for_parsing(self, content) then
    return false
  end

  -- Check if content contains NestJS HTTP method decorators
  return self:_is_nestjs_decorator_content(content)
end

---Gets parsing confidence for NestJS decorators
function NestJsParser:get_parsing_confidence(content)
  if not self:is_content_valid_for_parsing(content) then
    return 0.0
  end

  local base_confidence = 0.9
  local confidence_boost = 0

  -- Boost for HTTP method decorators
  if content:match "@(Get|Post|Put|Delete|Patch)%s*%(" then
    confidence_boost = confidence_boost + 0.05
  end

  -- Boost for HttpCode decorator presence
  if self:_has_http_code_decorator(content) then
    confidence_boost = confidence_boost + 0.03
  end

  -- Boost for well-formed paths
  local path = self:extract_endpoint_path(content)
  if path and path:match "^/" then
    confidence_boost = confidence_boost + 0.02
  end

  return math.min(base_confidence + confidence_boost, 1.0)
end

-- ========================================
-- PRIVATE METHODS
-- ========================================

---Checks if content looks like NestJS decorator content
function NestJsParser:_is_nestjs_decorator_content(content)
  -- Check for NestJS HTTP method decorators
  return content:match "@(Get|Post|Put|Delete|Patch|Options|Head)%s*%("
    or content:match "@HttpCode.-@(Get|Post|Put|Delete|Patch)"
end

---Checks if this is a @Controller decorator
function NestJsParser:_is_controller_decorator(content)
  return content:match "@Controller%s*%("
end

---Extracts the decorator type from content
function NestJsParser:_extract_decorator_type(content)
  local decorator = content:match "@(%w+)%s*%("
  if decorator then
    return decorator:lower()
  end
  return "unknown"
end

---Checks if content has @HttpCode decorator
function NestJsParser:_has_http_code_decorator(content)
  return content:match "@HttpCode" ~= nil
end

---Gets controller base path from @Controller decorator
function NestJsParser:_get_controller_path(file_path)
  local file = io.open(file_path, "r")
  if not file then
    return ""
  end

  local content = file:read "*all"
  file:close()

  -- Look for @Controller('path') decorator
  local controller_path = content:match "@Controller%s*%(%s*[\"']([^\"']*)[\"']"
  if controller_path then
    -- Ensure path starts with /
    if not controller_path:match "^/" then
      return "/" .. controller_path
    end
    return controller_path
  end

  -- @Controller() without parameter - no base path
  if content:match "@Controller%s*%(%s*%)" then
    return ""
  end

  return ""
end

---Combines controller path with endpoint path
function NestJsParser:_combine_paths(base, endpoint)
  if not base or base == "" then
    return endpoint or "/"
  end
  if not endpoint or endpoint == "" then
    return base
  end

  -- Remove trailing slash from base and leading slash from endpoint
  base = base:gsub("/$", "")
  endpoint = endpoint:gsub("^/", "")

  -- Handle root endpoint case
  if endpoint == "" then
    return base
  end

  return base .. "/" .. endpoint
end

return NestJsParser
