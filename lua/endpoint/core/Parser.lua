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

  -- Remove trailing slash from base and leading slash from endpoint
  base_path = base_path:gsub("/$", "")
  endpoint_path = endpoint_path:gsub("^/", "")

  -- Handle root endpoint case
  if endpoint_path == "" then
    return base_path
  end

  return base_path .. "/" .. endpoint_path
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

return Parser
