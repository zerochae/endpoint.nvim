local Parser = require "endpoint.core.Parser"

---@class endpoint.AnnotationParser
local AnnotationParser = setmetatable({}, { __index = Parser })
AnnotationParser.__index = AnnotationParser

---Creates a new AnnotationParser instance
function AnnotationParser:new(annotation_patterns, path_extraction_patterns, method_mapping, parser_name)
  local annotation_parser = Parser:new(parser_name or "annotation_parser", {
    annotation_patterns = annotation_patterns or {},
    path_extraction_patterns = path_extraction_patterns or {},
    method_mapping = method_mapping or {},
  })
  setmetatable(annotation_parser, self)
  return annotation_parser
end

---Parses annotation content to extract endpoint information
function AnnotationParser:parse_content(
  annotation_content,
  source_file_path,
  source_line_number,
  source_column_position
)
  if not self:is_content_valid_for_parsing(annotation_content) then
    return nil
  end

  -- Extract HTTP method from annotation
  local detected_http_method = self:_extract_http_method_from_annotation(annotation_content)
  if not detected_http_method then
    return nil
  end

  -- Extract endpoint path from annotation
  local extracted_endpoint_path = self:_extract_endpoint_path_from_annotation(annotation_content)
  if not extracted_endpoint_path then
    return nil
  end

  -- Create endpoint entry
  local endpoint_entry = {
    method = detected_http_method,
    endpoint_path = extracted_endpoint_path,
    file_path = source_file_path,
    line_number = source_line_number,
    column = source_column_position,
    display_value = detected_http_method .. " " .. extracted_endpoint_path,
    confidence = self:get_parsing_confidence(annotation_content),
    tags = { "annotation", "api" },
    metadata = {
      annotation_content = annotation_content,
      parser = self:get_name(),
    },
  }

  return endpoint_entry
end

---Extracts HTTP method from annotation content
function AnnotationParser:_extract_http_method_from_annotation(annotation_content)
  -- Check direct method mapping first
  for annotation_name, http_method in pairs(self.method_mapping) do
    if annotation_content:match(annotation_name) then
      return http_method:upper()
    end
  end

  -- Check annotation patterns
  for http_method, pattern_list in pairs(self.annotation_patterns) do
    for _, annotation_pattern in ipairs(pattern_list) do
      if annotation_content:match(annotation_pattern) then
        return http_method:upper()
      end
    end
  end

  return nil
end

---Extracts endpoint path from annotation content
function AnnotationParser:_extract_endpoint_path_from_annotation(annotation_content)
  for _, path_pattern in ipairs(self.path_extraction_patterns) do
    local extracted_path = annotation_content:match(path_pattern)
    if extracted_path then
      return extracted_path
    end
  end

  -- If no explicit path found, assume root path for parameterless annotations
  if annotation_content:match "@%w+%s*$" or annotation_content:match "@%w+%s*%(%s*%)" then
    return "/"
  end

  return nil
end

---Validates if content contains annotations suitable for parsing
function AnnotationParser:is_content_valid_for_parsing(content_to_validate)
  if not Parser.is_content_valid_for_parsing(self, content_to_validate) then
    return false
  end

  -- Check if content contains any recognizable annotation patterns
  for _, pattern_list in pairs(self.annotation_patterns) do
    for _, annotation_pattern in ipairs(pattern_list) do
      if content_to_validate:match(annotation_pattern) then
        return true
      end
    end
  end

  -- Check method mapping patterns
  for annotation_name, _ in pairs(self.method_mapping) do
    if content_to_validate:match(annotation_name) then
      return true
    end
  end

  return false
end

---Gets parsing confidence based on annotation recognition
function AnnotationParser:get_parsing_confidence(content_to_analyze)
  if not self:is_content_valid_for_parsing(content_to_analyze) then
    return 0.0
  end

  local base_confidence_score = 0.7
  local confidence_boost_amount = 0

  -- Boost confidence if both method and path are clearly defined
  local has_clear_method = self:_extract_http_method_from_annotation(content_to_analyze) ~= nil
  local has_clear_path = self:_extract_endpoint_path_from_annotation(content_to_analyze) ~= nil

  if has_clear_method then
    confidence_boost_amount = confidence_boost_amount + 0.15
  end

  if has_clear_path then
    confidence_boost_amount = confidence_boost_amount + 0.15
  end

  return math.min(base_confidence_score + confidence_boost_amount, 1.0)
end

---Adds additional annotation patterns for a specific HTTP method
function AnnotationParser:add_annotation_patterns(http_method, additional_patterns)
  if not self.annotation_patterns[http_method] then
    self.annotation_patterns[http_method] = {}
  end

  for _, additional_pattern in ipairs(additional_patterns) do
    table.insert(self.annotation_patterns[http_method], additional_pattern)
  end
end

---Adds additional path extraction patterns
function AnnotationParser:add_path_extraction_patterns(additional_path_patterns)
  for _, additional_pattern in ipairs(additional_path_patterns) do
    table.insert(self.path_extraction_patterns, additional_pattern)
  end
end

return AnnotationParser
