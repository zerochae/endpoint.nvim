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
  -- Handle GraphQL decorators first
  if self:_is_graphql_decorator(content) then
    local graphql_name = self:_extract_graphql_name(content)
    -- If GraphQL name extraction returns nil (decorator only), don't parse this content
    if not graphql_name then
      return nil
    end
    return graphql_name
  end

  -- @Get('path'), @Post("path"), etc. - only HTTP method decorators
  local path = content:match "@Get%s*%(%s*[\"']([^\"']+)[\"']"
    or content:match "@Post%s*%(%s*[\"']([^\"']+)[\"']"
    or content:match "@Put%s*%(%s*[\"']([^\"']+)[\"']"
    or content:match "@Delete%s*%(%s*[\"']([^\"']+)[\"']"
    or content:match "@Patch%s*%(%s*[\"']([^\"']+)[\"']"
    or content:match "@Options%s*%(%s*[\"']([^\"']+)[\"']"
    or content:match "@Head%s*%(%s*[\"']([^\"']+)[\"']"
  if path then
    -- Ensure path starts with /
    if not path:match "^/" then
      return "/" .. path
    end
    return path
  end

  -- @Get() without parameter - root path
  if
    content:match "@Get%s*%(%s*%)"
    or content:match "@Post%s*%(%s*%)"
    or content:match "@Put%s*%(%s*%)"
    or content:match "@Delete%s*%(%s*%)"
    or content:match "@Patch%s*%(%s*%)"
    or content:match "@Options%s*%(%s*%)"
    or content:match "@Head%s*%(%s*%)"
  then
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

---Override parse_content to handle multiline GraphQL decorators
function NestJsParser:parse_content(content, file_path, line_number, column)
  -- First try the standard parsing
  local result = Parser.parse_content(self, content, file_path, line_number, column)
  if result then
    return result
  end

  -- If standard parsing failed and this looks like an incomplete decorator,
  -- try to read extended context from the file
  if
    (self:_is_graphql_decorator(content) or self:_is_rest_decorator(content))
    and self:_looks_like_incomplete_decorator(content)
  then
    local extended_content, end_line = self:_get_extended_decorator_content(file_path, line_number)
    if extended_content then
      local extended_result = Parser.parse_content(self, extended_content, file_path, line_number, column)
      if extended_result and end_line then
        extended_result.end_line_number = end_line
      end
      return extended_result
    end
  end

  return nil
end

---Gets parsing confidence for NestJS decorators
function NestJsParser:get_parsing_confidence(content)
  if not self:is_content_valid_for_parsing(content) then
    return 0.0
  end

  local base_confidence = 0.9
  local confidence_boost = 0

  -- Boost for HTTP method decorators
  if
    content:match "@Get%s*%("
    or content:match "@Post%s*%("
    or content:match "@Put%s*%("
    or content:match "@Delete%s*%("
    or content:match "@Patch%s*%("
  then
    confidence_boost = confidence_boost + 0.05
  end

  -- Boost for GraphQL decorators
  if content:match "@Query%s*%(" or content:match "@Mutation%s*%(" then
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
  if
    content:match "@Get%s*%("
    or content:match "@Post%s*%("
    or content:match "@Put%s*%("
    or content:match "@Delete%s*%("
    or content:match "@Patch%s*%("
    or content:match "@Options%s*%("
    or content:match "@Head%s*%("
  then
    return true
  end

  -- Special handling for @Query - reject if it's clearly a parameter decorator first
  -- @Query('paramName') is parameter, @Query(() => Type) is GraphQL
  if content:match "@Query%s*%(%s*[\"'][^\"']*[\"']" then
    return false
  end

  -- Check for GraphQL decorators
  if content:match "@Query%s*%(" or content:match "@Mutation%s*%(" then
    return true
  end

  -- Check for HttpCode decorator followed by HTTP method
  if
    content:match "@HttpCode.-@Get"
    or content:match "@HttpCode.-@Post"
    or content:match "@HttpCode.-@Put"
    or content:match "@HttpCode.-@Delete"
    or content:match "@HttpCode.-@Patch"
    or content:match "@HttpCode.-@Options"
    or content:match "@HttpCode.-@Head"
  then
    return true
  end

  -- Check for common NestJS decorator patterns (case-insensitive)
  local case_insensitive_pattern = "@[Gg][Ee][Tt]%s*%("
    or content:match "@[Pp][Oo][Ss][Tt]%s*%("
    or content:match "@[Pp][Uu][Tt]%s*%("
    or content:match "@[Dd][Ee][Ll][Ee][Tt][Ee]%s*%("
    or content:match "@[Pp][Aa][Tt][Cc][Hh]%s*%("

  if case_insensitive_pattern then
    return true
  end

  -- Reject decorators that are not endpoint-related (like @Args, @Param, @Body, etc.)
  -- Note: Be careful with @Query as it can be both GraphQL @Query and HTTP @Query parameter
  if
    content:match "@Args%s*%("
    or content:match "@Param%s*%("
    or content:match "@Body%s*%("
    or content:match "@Headers%s*%("
    or content:match "@Req%s*%("
    or content:match "@Res%s*%("
    or content:match "@Next%s*%("
    or content:match "@Session%s*%("
    or content:match "@Ip%s*%("
    or content:match "@HostParam%s*%("
  then
    return false
  end

  return false
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

---Checks if content contains GraphQL decorators
function NestJsParser:_is_graphql_decorator(content)
  -- First, reject if it contains parameter decorators
  if content:match "@Query%s*%(%s*[\"'][^\"']*[\"']" then
    return false
  end

  -- Check for GraphQL @Query with type syntax: @Query(() => Type)
  if content:match "@Query%s*%(%s*%(%s*%)" or content:match "@Query%s*%(%s*%(%s*%)%s*=>" then
    return true
  end

  -- Check for @Mutation with type syntax: @Mutation(() => Type)
  if content:match "@Mutation%s*%(%s*%(%s*%)" or content:match "@Mutation%s*%(%s*%(%s*%)%s*=>" then
    return true
  end

  -- Also check case variations for GraphQL decorators
  if
    content:match "@[Qq][Uu][Ee][Rr][Yy]%s*%(%s*%(%s*%)"
    or content:match "@[Mm][Uu][Tt][Aa][Tt][Ii][Oo][Nn]%s*%(%s*%(%s*%)"
  then
    return true
  end

  return false
end

---Extracts GraphQL query/mutation name from decorator
function NestJsParser:_extract_graphql_name(content)
  -- Try to extract name from decorator options: @Query(() => Type, { name: 'customName' })
  local name_from_options = content:match "@%w+%s*%([^}]-name%s*:%s*[\"']([^\"']+)[\"']"
  if name_from_options then
    return name_from_options
  end

  -- If no explicit name, look for function name after the decorator
  -- Try multiple patterns in order of specificity
  local function_name =
    -- Pattern 1: @Decorator(...)\n  async functionName(
    content:match "@%w+%s*%(.-%)%s*\n%s*async%s+(%w+)%s*%("
    -- Pattern 2: @Decorator(...)\n  functionName(
    or content:match "@%w+%s*%(.-%)%s*\n%s*(%w+)%s*%("
    -- Pattern 3: @Decorator(...) async functionName( (same line, with space)
    or content:match "@%w+%s*%(.-%)%s*async%s+(%w+)%s*%("
    -- Pattern 4: @Decorator(...) functionName( (same line, with space)
    or content:match "@%w+%s*%(.-%)%s+(%w+)%s*%("
    -- Pattern 5: Handle multiline decorator with async keyword
    or content:match "@%w+.-\n%s*async%s+(%w+)%s*%("
    -- Pattern 6: Handle multiline decorator without async keyword
    or content:match "@%w+.-\n%s*(%w+)%s*%("
    -- Pattern 7: Simple async pattern as fallback
    or content:match "async%s+(%w+)%s*%("

  if function_name then
    return function_name
  end

  -- Special case: if content is just a decorator line, return nil
  -- This signals that we need more context to extract the function name
  local decorator_only = content:match "^%s*@%w+%s*%(.-%)%s*$"
    or content:match "^%s*@%w+%s*%(.-{%s*$" -- Handles multiline decorators ending with {
    or content:match "^%s*@%w+%s*%(.-,$" -- Handles incomplete decorators ending with ,

  if decorator_only then
    return nil -- Need more context
  end

  -- Fallback: return the decorator type only if we have some function context
  local decorator_type = content:match "@(%w+)%s*%("
  if decorator_type then
    return decorator_type:lower()
  end

  return "unknown"
end

---Checks if content contains REST API decorators
function NestJsParser:_is_rest_decorator(content)
  -- Check for HTTP method decorators
  if
    content:match "@Get%s*%("
    or content:match "@Post%s*%("
    or content:match "@Put%s*%("
    or content:match "@Delete%s*%("
    or content:match "@Patch%s*%("
    or content:match "@Options%s*%("
    or content:match "@Head%s*%("
  then
    return true
  end
  return false
end

---Checks if content looks like an incomplete decorator
function NestJsParser:_looks_like_incomplete_decorator(content)
  -- Check for patterns that indicate incomplete decorators
  local incomplete_patterns = {
    "^%s*@%w+%s*%(.-{%s*$", -- Ends with opening brace
    "^%s*@%w+%s*%(.-,%s*$", -- Ends with comma
    "^%s*@%w+%s*%($", -- Decorator with opening paren only (like "@Get(")
  }

  for _, pattern in ipairs(incomplete_patterns) do
    if content:match(pattern) then
      return true
    end
  end

  -- Special case for decorators that don't close properly
  -- Count parentheses to see if they're balanced
  local open_count = 0
  local close_count = 0
  for char in content:gmatch "." do
    if char == "(" then
      open_count = open_count + 1
    elseif char == ")" then
      close_count = close_count + 1
    end
  end

  -- If we have unbalanced parentheses and it starts with @decorator(
  if open_count > close_count and content:match "^%s*@%w+%s*%(" then
    return true
  end

  return false
end

---Gets extended content for decorators by reading surrounding lines
function NestJsParser:_get_extended_decorator_content(file_path, start_line)
  if not file_path then
    return nil
  end

  local file = io.open(file_path, "r")
  if not file then
    return nil
  end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  -- Read from decorator start until we find a complete decorator + function
  local extended_lines = {}
  local max_lines = 15 -- Limit search to prevent infinite loops
  local paren_count = 0
  local decorator_complete = false
  local decorator_end_line = start_line

  for i = start_line, math.min(start_line + max_lines - 1, #lines) do
    if lines[i] then
      table.insert(extended_lines, lines[i])

      -- Count parentheses to track decorator completion
      for char in lines[i]:gmatch "." do
        if char == "(" then
          paren_count = paren_count + 1
        elseif char == ")" then
          paren_count = paren_count - 1
        end
      end

      -- If parentheses are balanced and we haven't marked completion yet, decorator is complete
      if paren_count == 0 and #extended_lines > 1 and not decorator_complete then
        decorator_complete = true
        decorator_end_line = i -- Record where decorator ends (for highlighting)
      end

      -- After decorator is complete, look for function declaration to finish parsing
      if decorator_complete then
        if
          lines[i]:match "async%s+%w+%s*%("
          or (lines[i]:match "%w+%s*%(" and not lines[i]:match "@%w+" and not lines[i]:match ":%s")
        then
          break
        end
      end
    end
  end

  if #extended_lines >= 1 then
    return table.concat(extended_lines, "\n"), decorator_end_line
  end

  return nil, nil
end

return NestJsParser
