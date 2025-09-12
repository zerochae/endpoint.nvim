-- Symfony Framework Implementation (Function-based)
local M = {}

-- Detection
function M.detect()
  return vim.fn.filereadable("composer.json") == 1 
    and vim.fn.isdirectory("vendor/symfony") == 1
end

-- Search command generation
function M.get_search_cmd(method)
  local patterns = {
    GET = { "#\\[Route\\(.*methods.*GET", "@Route\\(.*methods.*GET" },
    POST = { "#\\[Route\\(.*methods.*POST", "@Route\\(.*methods.*POST" },
    PUT = { "#\\[Route\\(.*methods.*PUT", "@Route\\(.*methods.*PUT" },
    DELETE = { "#\\[Route\\(.*methods.*DELETE", "@Route\\(.*methods.*DELETE" },
    PATCH = { "#\\[Route\\(.*methods.*PATCH", "@Route\\(.*methods.*PATCH" },
    ALL = { "#\\[Route", "@Route" },
  }
  
  local method_patterns = patterns[method:upper()] or patterns.ALL
  
  local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"
  cmd = cmd .. " --glob '**/*.php'"
  cmd = cmd .. " --glob '!**/vendor/**'"
  cmd = cmd .. " --glob '!**/var/**'"
  
  -- Add patterns
  for _, pattern in ipairs(method_patterns) do
    cmd = cmd .. " -e '" .. pattern .. "'"
  end
  
  return cmd
end

-- Line parsing
function M.parse_line(line, method)
  local file_path, line_number, column, content = line:match("([^:]+):(%d+):(%d+):(.*)")
  if not file_path then return nil end
  
  -- Extract endpoint path
  local endpoint_path = M.extract_path(content)
  if not endpoint_path then return nil end
  
  -- Extract HTTP method
  local parsed_method = M.extract_method(content, method)
  
  return {
    file_path = file_path,
    line_number = tonumber(line_number),
    column = tonumber(column),
    method = parsed_method,
    endpoint_path = endpoint_path,
    display_value = parsed_method .. " " .. endpoint_path
  }
end

-- Extract path from Symfony Route annotations/attributes
function M.extract_path(content)
  -- #[Route('/path', methods: ['GET'])] (PHP 8 attributes)
  local path = content:match('#%[Route%(%s*["\']([^"\']+)["\']')
  if path then return path end
  
  -- @Route("/path", methods={"GET"}) (annotations)
  path = content:match('@Route%(%s*["\']([^"\']+)["\']')
  if path then return path end
  
  return nil
end

-- Extract HTTP method
function M.extract_method(content, search_method)
  -- If searching for specific method, return it
  if search_method ~= "ALL" then
    return search_method:upper()
  end
  
  -- Extract from methods parameter
  local method = content:match('methods[^%[]*%[%s*["\']([^"\']+)["\']')
  if method then
    return method:upper()
  end
  
  return "GET"
end

return M