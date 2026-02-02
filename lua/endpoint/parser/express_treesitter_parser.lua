-- Tree-sitter based Express.js endpoint parser
local TreeSitterParser = require "endpoint.core.TreeSitterParser"
local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"

---@class endpoint.ExpressTreeSitterParser : endpoint.core.TreeSitterParser
local ExpressTreeSitterParser = class("ExpressTreeSitterParser", TreeSitterParser)

local METHOD_MAP = {
  get = "GET",
  post = "POST",
  put = "PUT",
  delete = "DELETE",
  patch = "PATCH",
  all = "ALL",
  options = "OPTIONS",
  head = "HEAD",
}

function ExpressTreeSitterParser:initialize()
  TreeSitterParser.initialize(self, {
    parser_name = "express_treesitter_parser",
    framework_name = "express",
    language = "javascript",
  })
end

---Check if Tree-sitter JavaScript/TypeScript parser is available
---@return boolean
function ExpressTreeSitterParser:is_available()
  return self:is_treesitter_available("javascript") or self:is_treesitter_available("typescript")
end

---Get the appropriate language for the file
---@param file_path string
---@return string
function ExpressTreeSitterParser:_get_language(file_path)
  if file_path:match "%.ts$" or file_path:match "%.tsx$" then
    return "typescript"
  end
  return "javascript"
end

---Extract endpoints from an Express.js file
---@param file_path string Path to the file
---@param options table|nil Options
---@return table[] endpoints
function ExpressTreeSitterParser:extract_endpoints(file_path, options)
  options = options or {}
  local endpoints = {}

  local lang = self:_get_language(file_path)
  if not self:is_treesitter_available(lang) then
    log.framework_debug("Tree-sitter " .. lang .. " parser not available")
    return endpoints
  end

  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return endpoints
  end
  local content = table.concat(lines, "\n")

  local parser_ok, parser = pcall(vim.treesitter.get_string_parser, content, lang)
  if not parser_ok or not parser then
    log.framework_debug("Failed to create " .. lang .. " parser")
    return endpoints
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return endpoints
  end

  local tree = trees[1]
  local root = tree:root()

  -- Find route definitions
  local route_endpoints = self:_find_routes(root, content, file_path, lang, options)
  vim.list_extend(endpoints, route_endpoints)

  return endpoints
end

---Find Express route definitions
---@param root userdata Tree-sitter root node
---@param content string File content
---@param file_path string File path
---@param lang string Language (javascript or typescript)
---@param options table Options
---@return table[] endpoints
function ExpressTreeSitterParser:_find_routes(root, content, file_path, lang, options)
  local endpoints = {}

  local query_string = [[
    (call_expression
      function: (member_expression
        object: (identifier) @object
        property: (property_identifier) @method
      )
      arguments: (arguments
        (string (string_fragment) @path)?
        (template_string)? @template
      )
    ) @call
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, lang, query_string)
  if not query_ok or not query then
    log.framework_debug "Failed to parse Express route query"
    return endpoints
  end

  local current_object = nil
  local current_method = nil
  local current_path = nil

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]

    if name == "object" then
      current_object = vim.treesitter.get_node_text(node, content)
    elseif name == "method" then
      current_method = vim.treesitter.get_node_text(node, content)
    elseif name == "path" then
      current_path = vim.treesitter.get_node_text(node, content)
    elseif name == "template" then
      -- Handle template strings
      local template_text = vim.treesitter.get_node_text(node, content)
      current_path = template_text:gsub("^`", ""):gsub("`$", "")
    elseif name == "call" then
      -- Check if this is a valid Express route
      if current_object and (current_object == "app" or current_object == "router" or current_object == "Router") then
        if current_method and METHOD_MAP[current_method] then
          local http_method = METHOD_MAP[current_method]

          if not options.method or options.method == "" or http_method:upper() == options.method:upper() then
            local endpoint_path = current_path or "/"
            local start_row = node:range()

            table.insert(endpoints, {
              method = http_method,
              endpoint_path = endpoint_path,
              file_path = file_path,
              line_number = start_row + 1,
              column = 1,
              display_value = http_method .. " " .. endpoint_path,
              confidence = 0.95,
              tags = { lang, "express", "treesitter" },
              metadata = {
                parser = self.parser_name,
                framework_version = "express",
                language = lang,
                source = "treesitter",
              },
            })
          end
        end
      end

      current_object = nil
      current_method = nil
      current_path = nil
    end
  end

  return endpoints
end

return ExpressTreeSitterParser
