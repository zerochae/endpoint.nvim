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

---Validates if content contains NestJS decorators
function NestJsParser:is_content_valid_for_parsing(content)
  if not Parser.is_content_valid_for_parsing(self, content) then
    return false
  end

  -- Must be non-empty and trimmed content
  local trimmed = content:match "^%s*(.-)%s*$"
  if not trimmed or trimmed == "" then
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
  -- Check for NestJS HTTP method decorators with optional whitespace
  local http_method_pattern = "@(Get|Post|Put|Delete|Patch|Options|Head)%s*%("
  if content:match(http_method_pattern) then
    return true
  end

  -- Check for HttpCode decorator followed by HTTP method
  local http_code_pattern = "@HttpCode.-@(Get|Post|Put|Delete|Patch|Options|Head)"
  if content:match(http_code_pattern) then
    return true
  end

  -- Check for common NestJS decorator patterns (case-insensitive)
  local case_insensitive_pattern = "@[Gg][Ee][Tt]%s*%("
    or content:match "@[Pp][Oo][Ss][Tt]%s*%("
    or content:match "@[Pp][Uu][Tt]%s*%("
    or content:match "@[Dd][Ee][Ll][Ee][Tt][Ee]%s*%("
    or content:match "@[Pp][Aa][Tt][Cc][Hh]%s*%("

  return case_insensitive_pattern ~= nil
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
