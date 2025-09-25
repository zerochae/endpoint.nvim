---@class endpoint.Parser
local Parser = {}
Parser.__index = Parser

---Creates a new Parser instance with optional fields
function Parser:new(fields)
  local parser = setmetatable({}, self)

  parser.parser_name = "unknown_parser"
  parser.framework_name = "unknown"
  parser.language = "unknown"

  -- Set fields if provided
  if fields then
    for key, value in pairs(fields) do
      parser[key] = value
    end
  end

  return parser
end

---Extracts base path from file (controller/class level)
function Parser:extract_base_path()
  -- Must be implemented by subclasses
  error("extract_base_path() must be implemented by subclass: " .. self.parser_name)
end

---Extracts endpoint path from content (method level)
function Parser:extract_endpoint_path()
  -- Must be implemented by subclasses
  error("extract_endpoint_path() must be implemented by subclass: " .. self.parser_name)
end

---Extracts HTTP method from content
function Parser:extract_method()
  -- Must be implemented by subclasses
  error("extract_method() must be implemented by subclass: " .. self.parser_name)
end

---Combines base path with endpoint path
function Parser:combine_paths(base_path, endpoint_path)
  if not base_path or base_path == "" then
    return endpoint_path or ""
  end
  if not endpoint_path or endpoint_path == "" then
    return base_path
  end

  -- Special case: both paths are root "/"
  if base_path == "/" and endpoint_path == "/" then
    return "/"
  end

  -- Remove trailing slash from base and leading slash from endpoint
  local clean_base = base_path:gsub("/$", "")
  local clean_endpoint = endpoint_path:gsub("^/", "")

  -- Handle root endpoint case
  if clean_endpoint == "" then
    return clean_base == "" and "/" or clean_base
  end

  -- If base becomes empty after removing trailing slash, it was root
  if clean_base == "" then
    return "/" .. clean_endpoint
  end

  return clean_base .. "/" .. clean_endpoint
end

---Parses content to extract endpoint information (unified implementation)
function Parser:parse_content(content, file_path, line_number, column)
  if not self:is_content_valid_for_parsing(content) then
    return nil
  end

  -- Use the 4 core methods to create endpoint
  local base_path = self:extract_base_path(file_path, line_number)
  local endpoint_path = self:extract_endpoint_path(content, file_path, line_number)
  local method = self:extract_method(content)

  if not endpoint_path or not method then
    return nil
  end

  -- Combine paths
  local full_path = self:combine_paths(base_path, endpoint_path)

  -- Create endpoint entry
  return {
    method = method:upper(),
    endpoint_path = full_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = method:upper() .. " " .. full_path,
    confidence = self:get_parsing_confidence(content),
    tags = { "api" },
    metadata = self:create_metadata("endpoint", {
      base_path = base_path,
      raw_endpoint_path = endpoint_path,
    }, content),
  }
end

---Gets the name of this parser
function Parser:get_name()
  return self.parser_name
end

---Validates if the content is suitable for this parser
function Parser:is_content_valid_for_parsing(content_to_validate)
  -- Default implementation - can be overridden by subclasses
  return content_to_validate ~= nil and content_to_validate ~= ""
end

---Gets parsing confidence for the given content
function Parser:get_parsing_confidence(content_to_analyze)
  -- Default implementation - can be overridden by subclasses
  if self:is_content_valid_for_parsing(content_to_analyze) then
    return 0.5 -- Medium confidence by default
  else
    return 0.0 -- No confidence if content is invalid
  end
end

---Creates standard metadata for an endpoint
function Parser:create_metadata(route_type, extra_metadata, content)
  local metadata = {
    parser = self:get_name(),
    framework_version = self.framework_name or "unknown",
    language = self.language or "unknown",
    route_type = route_type,
    raw_content = content,
  }

  -- Add extra metadata if provided
  if extra_metadata then
    for key, value in pairs(extra_metadata) do
      metadata[key] = value
    end
  end

  return metadata
end

function Parser:is_commented_line(content, file_path, line_number, comment_patterns)
  if not comment_patterns or #comment_patterns == 0 then
    return false -- No comment patterns defined, don't filter
  end

  local trimmed = content:gsub("^%s+", "")

  -- Check if content starts with any comment pattern
  for _, pattern in ipairs(comment_patterns) do
    if trimmed:match(pattern) then
      return true
    end
  end

  -- Check for block comment context if file context is provided
  if file_path and line_number then
    local file = io.open(file_path, "r")
    if file then
      local lines = {}
      for line in file:lines() do
        table.insert(lines, line)
      end
      file:close()

      -- Check if we're inside a block comment
      if self:_is_inside_block_comment(lines, line_number) then
        return true
      end

      local actual_line = lines[line_number]
      if actual_line then
        local line_trimmed = actual_line:gsub("^%s+", "")
        for _, pattern in ipairs(comment_patterns) do
          if line_trimmed:match(pattern) then
            return true
          end
        end
      end
    end
  end

  return false
end

function Parser:_is_inside_block_comment(lines, line_number)
  if not lines or line_number < 1 or line_number > #lines then
    return false
  end

  -- Check backwards for block comment state
  local in_block_comment = false
  for i = 1, line_number do
    local line = lines[i]
    local pos = 1

    while pos <= #line do
      -- Look for block comment start
      local start_pos = line:find("/%*", pos)
      local end_pos = line:find("%*/", pos)

      -- Handle same line start and end
      if start_pos and end_pos and start_pos < end_pos then
        -- Block comment starts and ends on same line
        pos = end_pos + 2
      elseif start_pos and (not end_pos or start_pos < end_pos) then
        -- Block comment starts
        in_block_comment = true
        if end_pos then
          in_block_comment = false
          pos = end_pos + 2
        else
          break
        end
      elseif end_pos and (not start_pos or end_pos < start_pos) then
        -- Block comment ends
        in_block_comment = false
        pos = end_pos + 2
      else
        break
      end
    end
  end

  return in_block_comment
end

return Parser
