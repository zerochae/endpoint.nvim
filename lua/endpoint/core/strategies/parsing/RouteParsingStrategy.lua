local ParsingStrategy = require "endpoint.core.strategies.parsing.ParsingStrategy"

---@class endpoint.RouteParsingStrategy
---Route parsing strategy for frameworks that use route configuration files (Django, Rails)
local RouteParsingStrategy = setmetatable({}, { __index = ParsingStrategy })
RouteParsingStrategy.__index = RouteParsingStrategy

---Creates a new RouteParsingStrategy instance
function RouteParsingStrategy:new(route_patterns, path_extraction_patterns, route_processors, parsing_strategy_name)
  local route_parsing_strategy_instance = ParsingStrategy.new(self, parsing_strategy_name or "route_parsing")

  route_parsing_strategy_instance.route_patterns = route_patterns or {}
  route_parsing_strategy_instance.path_extraction_patterns = path_extraction_patterns or {}
  route_parsing_strategy_instance.route_processors = route_processors or {}

  setmetatable(route_parsing_strategy_instance, self)
  return route_parsing_strategy_instance
end

---Parses route content to extract endpoint information
function RouteParsingStrategy:parse_content(content, file_path, line_number, column)
  local detected_route_type = self:_detect_route_type(content)
  if not detected_route_type then
    return nil
  end

  local extracted_paths = self:_extract_paths_from_content(content)
  if not extracted_paths or #extracted_paths == 0 then
    return nil
  end

  local primary_path = extracted_paths[1]
  local http_method = self:_determine_http_method(content, detected_route_type)

  -- Use custom processor if available
  if self.route_processors[detected_route_type] then
    return self.route_processors[detected_route_type](self, content, file_path, line_number, column, primary_path, http_method)
  end

  -- Default endpoint creation
  return self:_create_endpoint_entry(content, file_path, line_number, column, primary_path, http_method)
end

---Detects the type of route pattern in the content
function RouteParsingStrategy:_detect_route_type(content)
  for route_type, patterns in pairs(self.route_patterns) do
    for _, pattern in ipairs(patterns) do
      if content:match(pattern) then
        return route_type
      end
    end
  end
  return nil
end

---Extracts paths from the content using configured patterns
function RouteParsingStrategy:_extract_paths_from_content(content)
  local extracted_paths = {}

  for _, extraction_pattern in ipairs(self.path_extraction_patterns) do
    local path_match = content:match(extraction_pattern)
    if path_match then
      table.insert(extracted_paths, path_match)
    end
  end

  return extracted_paths
end

---Determines HTTP method from content and route type
function RouteParsingStrategy:_determine_http_method(content, route_type)
  -- Default mapping based on route type
  local method_mapping = {
    ["get_route"] = "GET",
    ["post_route"] = "POST",
    ["put_route"] = "PUT",
    ["delete_route"] = "DELETE",
    ["patch_route"] = "PATCH",
    ["resources_route"] = "GET", -- Default for resources, processors can override
    ["path_route"] = "GET", -- Default for generic paths
    ["url_route"] = "GET" -- Default for URL patterns
  }

  return method_mapping[route_type] or "GET"
end

---Creates a basic endpoint entry
function RouteParsingStrategy:_create_endpoint_entry(content, file_path, line_number, column, endpoint_path, http_method)
  return {
    method = http_method,
    endpoint_path = endpoint_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = http_method .. " " .. endpoint_path,
    confidence = self:get_parsing_confidence(content),
    tags = {},
    metadata = {
      parsing_strategy = self:get_strategy_name(),
      raw_content = content
    }
  }
end

---Checks if content is valid for route parsing
function RouteParsingStrategy:is_content_valid_for_parsing(content)
  return self:_detect_route_type(content) ~= nil
end

---Gets parsing confidence for route content
function RouteParsingStrategy:get_parsing_confidence(content)
  local base_confidence = 0.7
  local confidence_boosts = 0.0

  -- Boost confidence for well-formed route patterns
  if content:match('["\']/[^"\']*["\']') then
    confidence_boosts = confidence_boosts + 0.1
  end

  -- Boost for explicit HTTP method keywords
  if content:match("get%s+") or content:match("post%s+") or content:match("put%s+") or
     content:match("delete%s+") or content:match("patch%s+") then
    confidence_boosts = confidence_boosts + 0.1
  end

  -- Boost for resource patterns
  if content:match("resources%s+") or content:match("resource%s+") then
    confidence_boosts = confidence_boosts + 0.1
  end

  return math.min(base_confidence + confidence_boosts, 1.0)
end

---Adds additional route patterns for a specific route type
function RouteParsingStrategy:add_route_patterns(route_type, additional_patterns)
  if not self.route_patterns[route_type] then
    self.route_patterns[route_type] = {}
  end

  for _, additional_pattern in ipairs(additional_patterns) do
    table.insert(self.route_patterns[route_type], additional_pattern)
  end
end

---Adds additional path extraction patterns
function RouteParsingStrategy:add_path_extraction_patterns(additional_path_patterns)
  for _, additional_pattern in ipairs(additional_path_patterns) do
    table.insert(self.path_extraction_patterns, additional_pattern)
  end
end

return RouteParsingStrategy
