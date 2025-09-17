---@class ParsingStrategy
local ParsingStrategy = {}
ParsingStrategy.__index = ParsingStrategy

---Creates a new ParsingStrategy instance
---@param parsing_strategy_name string Name of the parsing strategy
---@return ParsingStrategy
function ParsingStrategy:new(parsing_strategy_name)
  local parsing_strategy_instance = setmetatable({}, self)
  parsing_strategy_instance.parsing_strategy_name = parsing_strategy_name or "unknown_parsing"
  return parsing_strategy_instance
end

---Parses content to extract endpoint information
---@abstract
---@param _content_to_parse string The content to parse
---@param _source_file_path string Path to the source file
---@param _source_line_number number Line number in the source file
---@param _source_column_position number Column position in the source line
---@return endpoint.entry|nil parsed_endpoint The parsed endpoint or nil if parsing failed
function ParsingStrategy:parse_content(_content_to_parse, _source_file_path, _source_line_number, _source_column_position)
  error("parse_content() must be implemented by subclass: " .. self.parsing_strategy_name)
end

---Gets the name of this parsing strategy
---@return string strategy_name The name of the parsing strategy
function ParsingStrategy:get_strategy_name()
  return self.parsing_strategy_name
end

---Validates if the content is suitable for this parsing strategy
---@param content_to_validate string The content to validate
---@return boolean is_content_valid True if content can be parsed by this strategy
function ParsingStrategy:is_content_valid_for_parsing(content_to_validate)
  -- Default implementation - can be overridden by subclasses
  return content_to_validate ~= nil and content_to_validate ~= ""
end

---Gets parsing confidence for the given content
---@param content_to_analyze string The content to analyze
---@return number parsing_confidence Confidence score between 0 and 1
function ParsingStrategy:get_parsing_confidence(content_to_analyze)
  -- Default implementation - can be overridden by subclasses
  if self:is_content_valid_for_parsing(content_to_analyze) then
    return 0.5 -- Medium confidence by default
  else
    return 0.0 -- No confidence if content is invalid
  end
end

return ParsingStrategy