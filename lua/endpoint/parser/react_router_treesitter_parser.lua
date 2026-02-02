-- Tree-sitter based React Router endpoint parser
local TreeSitterParser = require "endpoint.core.TreeSitterParser"
local class = require "endpoint.lib.middleclass"
local log = require "endpoint.utils.log"

---@class endpoint.ReactRouterTreeSitterParser : endpoint.core.TreeSitterParser
local ReactRouterTreeSitterParser = class("ReactRouterTreeSitterParser", TreeSitterParser)

function ReactRouterTreeSitterParser:initialize()
  TreeSitterParser.initialize(self, {
    parser_name = "react_router_treesitter_parser",
    framework_name = "react_router",
    language = "javascript",
  })
end

---Check if Tree-sitter JavaScript/TypeScript parser is available
---@return boolean
function ReactRouterTreeSitterParser:is_available()
  return self:is_treesitter_available("javascript") or self:is_treesitter_available("tsx")
end

---Get the appropriate language for the file
---@param file_path string
---@return string
function ReactRouterTreeSitterParser:_get_language(file_path)
  if file_path:match "%.tsx$" then
    return "tsx"
  elseif file_path:match "%.ts$" then
    return "typescript"
  elseif file_path:match "%.jsx$" then
    return "javascript"
  end
  return "javascript"
end

---Extract endpoints from a React Router file
---@param file_path string Path to the file
---@param options table|nil Options
---@return table[] endpoints
function ReactRouterTreeSitterParser:extract_endpoints(file_path, options)
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

  -- Find Route elements
  local route_endpoints = self:_find_routes(root, content, file_path, lang, options)
  vim.list_extend(endpoints, route_endpoints)

  return endpoints
end

---Find React Router <Route> elements
---@param root userdata Tree-sitter root node
---@param content string File content
---@param file_path string File path
---@param lang string Language
---@param options table Options
---@return table[] endpoints
function ReactRouterTreeSitterParser:_find_routes(root, content, file_path, lang, options)
  local endpoints = {}

  local query_string = [[
    (jsx_self_closing_element
      name: (identifier) @tag_name
      attribute: (jsx_attribute
        (property_identifier) @attr_name
        (string (string_fragment) @attr_value)?
      )*
      (#eq? @tag_name "Route")
    ) @route
  ]]

  local query_ok, query = pcall(vim.treesitter.query.parse, lang, query_string)
  if not query_ok or not query then
    log.framework_debug "Failed to parse React Router query"
    return endpoints
  end

  local current_path = nil

  for id, node in query:iter_captures(root, content, 0, -1) do
    local name = query.captures[id]

    if name == "attr_name" then
      local attr_name = vim.treesitter.get_node_text(node, content)
      if attr_name == "path" then
        -- Next attr_value should be the path
      end
    elseif name == "attr_value" then
      current_path = vim.treesitter.get_node_text(node, content)
    elseif name == "route" then
      if current_path then
        if not options.method or options.method == "" or options.method:upper() == "GET" then
          local start_row = node:range()

          table.insert(endpoints, {
            method = "GET",
            endpoint_path = current_path,
            file_path = file_path,
            line_number = start_row + 1,
            column = 1,
            display_value = "GET " .. current_path,
            confidence = 0.90,
            tags = { lang, "react-router", "treesitter" },
            metadata = {
              parser = self.parser_name,
              framework_version = "react_router",
              language = lang,
              source = "treesitter",
            },
          })
        end
      end
      current_path = nil
    end
  end

  return endpoints
end

return ReactRouterTreeSitterParser
