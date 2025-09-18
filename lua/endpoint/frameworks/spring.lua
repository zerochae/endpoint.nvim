local Framework = require "endpoint.core.Framework"
local DependencyDetector = require "endpoint.detector.dependency_detector"
local AnnotationParser = require "endpoint.parser.annotation_parser"

---@class endpoint.SpringFramework
local SpringFramework = setmetatable({}, { __index = Framework })
SpringFramework.__index = SpringFramework

---Creates a new SpringFramework instance
function SpringFramework:new()
  local spring_framework_instance = Framework.new(self, "spring", {
    file_extensions = { "*.java", "*.kt" },
    exclude_patterns = { "**/target", "**/build", "**/.gradle" },
    patterns = {
      GET = { "@GetMapping", "@RequestMapping.*method.*=.*GET" },
      POST = { "@PostMapping", "@RequestMapping.*method.*=.*POST" },
      PUT = { "@PutMapping", "@RequestMapping.*method.*=.*PUT" },
      DELETE = { "@DeleteMapping", "@RequestMapping.*method.*=.*DELETE" },
      PATCH = { "@PatchMapping", "@RequestMapping.*method.*=.*PATCH" },
    },
    search_options = { "--case-sensitive", "--type", "java" }
  })
  setmetatable(spring_framework_instance, self)
  return spring_framework_instance
end

---Sets up detection and parsing for Spring
function SpringFramework:_initialize()
  -- Setup detector
  self.detector = DependencyDetector:new(
    { "spring-web", "spring-boot", "springframework" },
    { "pom.xml", "build.gradle", "build.gradle.kts" },
    "spring_dependency_detection"
  )

  -- Setup parser with Spring annotation patterns
  local spring_annotation_patterns = {
    GET = { "@GetMapping", "@RequestMapping.*method.*=.*GET" },
    POST = { "@PostMapping", "@RequestMapping.*method.*=.*POST" },
    PUT = { "@PutMapping", "@RequestMapping.*method.*=.*PUT" },
    DELETE = { "@DeleteMapping", "@RequestMapping.*method.*=.*DELETE" },
    PATCH = { "@PatchMapping", "@RequestMapping.*method.*=.*PATCH" },
    OPTIONS = { "@RequestMapping.*method.*=.*OPTIONS" },
    HEAD = { "@RequestMapping.*method.*=.*HEAD" }
  }

  local spring_path_extraction_patterns = {
    '%("([^"]+)"[^)]*%)',         -- @GetMapping("/path")
    "%('([^']+)'[^)]*%)",         -- @GetMapping('/path')
    'value%s*=%s*"([^"]+)"',      -- @RequestMapping(value = "/path")
    "value%s*=%s*'([^']+)'",      -- @RequestMapping(value = '/path')
    'path%s*=%s*"([^"]+)"',       -- @RequestMapping(path = "/path")
    "path%s*=%s*'([^']+)'"        -- @RequestMapping(path = '/path')
  }

  local spring_method_mapping = {
    ["@GetMapping"] = "GET",
    ["@PostMapping"] = "POST",
    ["@PutMapping"] = "PUT",
    ["@DeleteMapping"] = "DELETE",
    ["@PatchMapping"] = "PATCH",
    ["@RequestMapping.*method.*=.*GET"] = "GET",
    ["@RequestMapping.*method.*=.*POST"] = "POST",
    ["@RequestMapping.*method.*=.*PUT"] = "PUT",
    ["@RequestMapping.*method.*=.*DELETE"] = "DELETE",
    ["@RequestMapping.*method.*=.*PATCH"] = "PATCH"
  }

  self.parser = AnnotationParser:new(
    spring_annotation_patterns,
    spring_path_extraction_patterns,
    spring_method_mapping
  )
end

---Detects if Spring is present in the current project
function SpringFramework:detect()
  return self.detector:is_target_detected()
end

---Parses Spring content to extract endpoint information
function SpringFramework:parse(content, file_path, line_number, column)
  local parsed_endpoint = self.parser:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- Extract controller base path
    local controller_base_path = self:_extract_controller_base_path(file_path, line_number)
    if controller_base_path and controller_base_path ~= "" then
      -- Combine base path with endpoint path
      local combined_path = self:_combine_paths(controller_base_path, parsed_endpoint.endpoint_path)
      parsed_endpoint.endpoint_path = combined_path
      parsed_endpoint.display_value = parsed_endpoint.method .. " " .. combined_path
    end

    -- Enhance with Spring-specific metadata
    parsed_endpoint.tags = parsed_endpoint.tags or {}
    table.insert(parsed_endpoint.tags, "java")
    table.insert(parsed_endpoint.tags, "spring")

    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "spring"
    parsed_endpoint.metadata.language = "java"
    parsed_endpoint.metadata.controller_base_path = controller_base_path

    -- Extract controller class name
    local controller_class_name = file_path:match("([^/]+)%.java$") or file_path:match("([^/]+)%.kt$")
    if controller_class_name then
      parsed_endpoint.metadata.controller_name = controller_class_name
    end

    -- Calculate confidence score
    parsed_endpoint.confidence = self:_calculate_spring_confidence(parsed_endpoint)
  end

  return parsed_endpoint
end

---Extracts controller base path from @RequestMapping annotation
function SpringFramework:_extract_controller_base_path(file_path, current_line_number)
  local fs = require "endpoint.utils.fs"
  local file_lines = fs.read_file(file_path)

  if not file_lines then
    return nil
  end

  -- Search backwards from current line for class-level @RequestMapping
  for i = current_line_number - 1, 1, -1 do
    local line = file_lines[i]
    if line and line:match("@RequestMapping") then
      -- Extract path from @RequestMapping
      local path = line:match('@RequestMapping%s*%(%s*["\']([^"\']+)["\']')
      if not path then
        path = line:match('value%s*=%s*["\']([^"\']+)["\']')
      end
      if not path then
        path = line:match('path%s*=%s*["\']([^"\']+)["\']')
      end
      return path
    end
    -- Stop if we hit a class declaration
    if line and line:match("class%s+%w+") then
      break
    end
  end

  return nil
end

---Combines base path with endpoint path
function SpringFramework:_combine_paths(base_path, endpoint_path)
  if not base_path or base_path == "" then
    return endpoint_path
  end

  if not endpoint_path or endpoint_path == "" then
    return base_path
  end

  -- Normalize paths
  local normalized_base = base_path:gsub("/$", "")
  local normalized_endpoint = endpoint_path:gsub("^/", "")

  if normalized_endpoint == "" then
    return normalized_base
  end

  return normalized_base .. "/" .. normalized_endpoint
end

---Calculates Spring-specific confidence score
function SpringFramework:_calculate_spring_confidence(endpoint)
  local base_confidence = 0.8
  local confidence_boost = 0

  -- Boost for well-formed paths
  if endpoint.endpoint_path and endpoint.endpoint_path:match("^/") then
    confidence_boost = confidence_boost + 0.1
  end

  -- Boost for standard HTTP methods
  local standard_methods = { GET = true, POST = true, PUT = true, DELETE = true, PATCH = true }
  if endpoint.method and standard_methods[endpoint.method] then
    confidence_boost = confidence_boost + 0.1
  end

  return math.min(base_confidence + confidence_boost, 1.0)
end

return SpringFramework
