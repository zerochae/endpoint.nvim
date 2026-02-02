-- Tree-sitter based Spring Boot endpoint parser
local TreeSitterParser = require "endpoint.core.TreeSitterParser"
local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"

---@class endpoint.SpringTreeSitterParser : endpoint.core.TreeSitterParser
local SpringTreeSitterParser = class("SpringTreeSitterParser", TreeSitterParser)

-- Mapping annotation to HTTP method
local ANNOTATION_TO_METHOD = {
  GetMapping = "GET",
  PostMapping = "POST",
  PutMapping = "PUT",
  DeleteMapping = "DELETE",
  PatchMapping = "PATCH",
  RequestMapping = "ROUTE",
}

function SpringTreeSitterParser:initialize()
  TreeSitterParser.initialize(self, {
    parser_name = "spring_treesitter_parser",
    framework_name = "spring",
    language = "java",
  })

  -- Load query from .scm file
  self._query = nil
  self._query_loaded = false
end

---Load the endpoints.scm query file
---@return userdata|nil query
function SpringTreeSitterParser:_get_query()
  if self._query_loaded then
    return self._query
  end

  self._query_loaded = true

  -- Find the query file relative to this plugin
  local query_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h") .. "/queries/java/endpoints.scm"

  local ok, content = pcall(vim.fn.readfile, query_path)
  if not ok or not content then
    log.framework_debug("Failed to load query file: " .. query_path)
    return nil
  end

  local query_string = table.concat(content, "\n")
  local query_ok, query = pcall(vim.treesitter.query.parse, "java", query_string)
  if not query_ok or not query then
    log.framework_debug "Failed to parse query"
    return nil
  end

  self._query = query
  return self._query
end

---Check if Tree-sitter Java parser is available
---@return boolean
function SpringTreeSitterParser:is_available()
  return self:is_treesitter_available("java")
end

---Extract endpoints from a Java/Spring file
---@param file_path string Path to the Java file
---@param options table|nil Options (method filter, etc.)
---@return table[] endpoints
function SpringTreeSitterParser:extract_endpoints(file_path, options)
  options = options or {}
  local endpoints = {}

  if not self:is_available() then
    log.framework_debug "Tree-sitter Java parser not available"
    return endpoints
  end

  -- Read file content
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return endpoints
  end
  local content = table.concat(lines, "\n")

  -- Parse with Tree-sitter
  local parser_ok, parser = pcall(vim.treesitter.get_string_parser, content, "java")
  if not parser_ok or not parser then
    log.framework_debug "Failed to create Java parser"
    return endpoints
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return endpoints
  end

  local tree = trees[1]
  local root = tree:root()

  -- First, find class-level base path
  local base_path = self:_find_class_base_path(root, content)

  -- Find all method-level mapping annotations
  local method_endpoints = self:_find_method_mappings(root, content, file_path, base_path, options)
  vim.list_extend(endpoints, method_endpoints)

  return endpoints
end

---Find class-level @RequestMapping base path
---@param root userdata Tree-sitter root node
---@param content string File content
---@return string base_path
function SpringTreeSitterParser:_find_class_base_path(root, content)
  local query_string = [[
    (class_declaration
      (modifiers
        (annotation
          name: (identifier) @anno_name
          arguments: (annotation_argument_list)? @anno_args
        )
        (#eq? @anno_name "RequestMapping")
      )
    )
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, "java", query_string)
  if not query_ok or not query then
    return ""
  end

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]
    if name == "anno_args" then
      local path = self:_extract_path_from_annotation_args(node, content)
      if path then
        return path
      end
    end
  end

  return ""
end

---Find method-level mapping annotations
---@param root userdata Tree-sitter root node
---@param content string File content
---@param file_path string File path
---@param base_path string Class-level base path
---@param options table Options
---@return table[] endpoints
function SpringTreeSitterParser:_find_method_mappings(root, content, file_path, base_path, options)
  local endpoints = {}

  local query_string = [[
    (method_declaration
      (modifiers
        (annotation
          name: (identifier) @anno_name
          arguments: (annotation_argument_list)? @anno_args
        ) @annotation
      )
      name: (identifier) @method_name
    ) @method
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, "java", query_string)
  if not query_ok or not query then
    log.framework_debug "Failed to parse method query"
    return endpoints
  end

  local current_anno_name = nil
  local current_anno_args = nil
  local current_method_name = nil

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]

    if name == "anno_name" then
      current_anno_name = vim.treesitter.get_node_text(node, content)
    elseif name == "anno_args" then
      current_anno_args = node
    elseif name == "method_name" then
      current_method_name = vim.treesitter.get_node_text(node, content)
    elseif name == "method" then
      -- Process the captured method
      if current_anno_name and ANNOTATION_TO_METHOD[current_anno_name] then
        local http_method = ANNOTATION_TO_METHOD[current_anno_name]
        local endpoint_path = ""

        if current_anno_args then
          endpoint_path = self:_extract_path_from_annotation_args(current_anno_args, content) or ""
        end

        -- Handle @RequestMapping with method parameter
        if current_anno_name == "RequestMapping" then
          local methods = self:_extract_methods_from_request_mapping(current_anno_args, content)
          if #methods > 0 then
            -- Create endpoint for each method
            for _, method in ipairs(methods) do
              if not options.method or options.method == "" or method:upper() == options.method:upper() then
                local full_path = self:_combine_paths(base_path, endpoint_path)
                local start_row = node:range()

                table.insert(endpoints, {
                  method = method:upper(),
                  endpoint_path = full_path,
                  file_path = file_path,
                  line_number = start_row + 1,
                  column = 1,
                  display_value = method:upper() .. " " .. full_path,
                  confidence = 0.95,
                  tags = { "java", "spring", "treesitter" },
                  metadata = {
                    parser = self.parser_name,
                    framework_version = "spring",
                    language = "java",
                    method_name = current_method_name,
                    annotation = current_anno_name,
                    source = "treesitter",
                  },
                })
              end
            end
          end
        else
          -- Specific mapping (@GetMapping, @PostMapping, etc.)
          if not options.method or options.method == "" or http_method:upper() == options.method:upper() then
            local full_path = self:_combine_paths(base_path, endpoint_path)
            local start_row = node:range()

            table.insert(endpoints, {
              method = http_method,
              endpoint_path = full_path,
              file_path = file_path,
              line_number = start_row + 1,
              column = 1,
              display_value = http_method .. " " .. full_path,
              confidence = 0.95,
              tags = { "java", "spring", "treesitter" },
              metadata = {
                parser = self.parser_name,
                framework_version = "spring",
                language = "java",
                method_name = current_method_name,
                annotation = current_anno_name,
                source = "treesitter",
              },
            })
          end
        end
      end

      -- Reset for next method
      current_anno_name = nil
      current_anno_args = nil
      current_method_name = nil
    end
  end

  return endpoints
end

---Extract path from annotation arguments node
---@param args_node userdata Annotation arguments node
---@param content string File content
---@return string|nil path
function SpringTreeSitterParser:_extract_path_from_annotation_args(args_node, content)
  if not args_node then
    return nil
  end

  -- Iterate through children to find string literals or element_value_pairs
  for child in args_node:iter_children() do
    local child_type = child:type()

    if child_type == "string_literal" then
      -- Direct string: @GetMapping("/path")
      local text = vim.treesitter.get_node_text(child, content)
      return text:gsub('^"', ""):gsub('"$', "")
    elseif child_type == "element_value_pair" then
      -- Named parameter: @GetMapping(value = "/path")
      local key_node = child:field("key")[1]
      local value_node = child:field("value")[1]

      if key_node and value_node then
        local key = vim.treesitter.get_node_text(key_node, content)
        if key == "value" or key == "path" then
          local value_text = vim.treesitter.get_node_text(value_node, content)
          return value_text:gsub('^"', ""):gsub('"$', "")
        end
      end
    end
  end

  return nil
end

---Extract HTTP methods from @RequestMapping annotation
---@param args_node userdata|nil Annotation arguments node
---@param content string File content
---@return table methods Array of HTTP method strings
function SpringTreeSitterParser:_extract_methods_from_request_mapping(args_node, content)
  local methods = {}

  if not args_node then
    return { "GET" } -- Default
  end

  for child in args_node:iter_children() do
    if child:type() == "element_value_pair" then
      local key_node = child:field("key")[1]
      local value_node = child:field("value")[1]

      if key_node then
        local key = vim.treesitter.get_node_text(key_node, content)
        if key == "method" and value_node then
          local value_text = vim.treesitter.get_node_text(value_node, content)

          -- Extract RequestMethod.XXX patterns
          for method in value_text:gmatch "RequestMethod%.(%w+)" do
            table.insert(methods, method:upper())
          end
        end
      end
    end
  end

  if #methods == 0 then
    return { "GET" }
  end

  return methods
end

---Combine base path and endpoint path
---@param base_path string
---@param endpoint_path string
---@return string
function SpringTreeSitterParser:_combine_paths(base_path, endpoint_path)
  if not base_path or base_path == "" then
    return endpoint_path ~= "" and endpoint_path or "/"
  end
  if not endpoint_path or endpoint_path == "" then
    return base_path
  end

  -- Remove trailing slash from base, leading slash from endpoint
  local clean_base = base_path:gsub("/$", "")
  local clean_endpoint = endpoint_path:gsub("^/", "")

  if clean_endpoint == "" then
    return clean_base ~= "" and clean_base or "/"
  end
  if clean_base == "" then
    return "/" .. clean_endpoint
  end

  return clean_base .. "/" .. clean_endpoint
end

return SpringTreeSitterParser
