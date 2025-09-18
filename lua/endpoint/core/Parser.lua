---@class endpoint.Parser
local Parser = {}
Parser.__index = Parser

---Creates a new Parser instance with optional fields
function Parser:new(parsing_name, fields)
  local parser_instance = setmetatable({}, self)
  parser_instance.parsing_name = parsing_name or "unknown_parsing"

  -- Set additional fields if provided
  if fields then
    for key, value in pairs(fields) do
      parser_instance[key] = value
    end
  end

  return parser_instance
end

---Parses content to extract endpoint information
function Parser:parse_content()
  error("parse_content() must be implemented by subclass: " .. self.parsing_name)
end

---Gets the name of this parser
function Parser:get_name()
  return self.parsing_name
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

return Parser
