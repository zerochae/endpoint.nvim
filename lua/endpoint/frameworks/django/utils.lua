-- Django Framework Utility Functions
---@class endpoint.frameworks.django.utils
local M = {}

-- Extract URL patterns from Django urls.py content
---@param content string[] Lines from urls.py file
---@return table[] url_patterns Array of {pattern, view, name} objects
function M.extract_url_patterns(content)
  local patterns = {}
  local in_urlpatterns = false
  local bracket_count = 0

  for i, line in ipairs(content) do
    -- Start of urlpatterns
    if line:match("urlpatterns%s*=") then
      in_urlpatterns = true
      bracket_count = 0
    end

    if in_urlpatterns then
      -- Count brackets to track nesting
      for char in line:gmatch(".") do
        if char == "[" or char == "(" then
          bracket_count = bracket_count + 1
        elseif char == "]" or char == ")" then
          bracket_count = bracket_count - 1
        end
      end

      -- Extract patterns
      local pattern_match = line:match("path%s*%((.-)%)") or
                           line:match("re_path%s*%((.-)%)") or
                           line:match("url%s*%((.-)%)")

      if pattern_match then
        local path_str, view_str, name_str = M.parse_url_pattern(pattern_match)
        if path_str and view_str then
          table.insert(patterns, {
            pattern = path_str,
            view = view_str,
            name = name_str,
            file_line = i
          })
        end
      end

      -- End of urlpatterns
      if bracket_count <= 0 and line:match("%]") then
        in_urlpatterns = false
      end
    end
  end

  return patterns
end

-- Parse individual URL pattern arguments
---@param pattern_args string Arguments inside path() or url()
---@return string? path
---@return string? view
---@return string? name
function M.parse_url_pattern(pattern_args)
  -- Remove whitespace and quotes
  pattern_args = pattern_args:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

  -- Extract path (first argument)
  local path = pattern_args:match("^['\"]([^'\"]*)['\"]") or
               pattern_args:match("^r['\"]([^'\"]*)['\"]")

  if not path then return nil, nil, nil end

  -- Extract view (second argument)
  local rest = pattern_args:gsub("^r?['\"][^'\"]*['\"]%s*,%s*", "")
  local view = rest:match("^([^,]+)")

  if view then
    view = view:gsub("^%s+", ""):gsub("%s+$", "")
    -- Remove .as_view() if present
    view = view:gsub("%.as_view%s*%(%)$", "")
  end

  -- Extract name (if present)
  local name = pattern_args:match("name%s*=%s*['\"]([^'\"]*)['\"]")

  return path, view, name
end

-- Determine HTTP methods from Django view
---@param view_name string Name of the view (class or function)
---@return string[] methods Array of HTTP methods
function M.determine_http_methods(view_name)
  -- Class-based view patterns
  local cbv_patterns = {
    ["ListView"] = {"GET"},
    ["DetailView"] = {"GET"},
    ["CreateView"] = {"GET", "POST"},
    ["UpdateView"] = {"GET", "POST", "PUT", "PATCH"},
    ["DeleteView"] = {"GET", "POST", "DELETE"},
    ["FormView"] = {"GET", "POST"},
    ["TemplateView"] = {"GET"},

    -- DRF patterns
    ["ListAPIView"] = {"GET"},
    ["CreateAPIView"] = {"POST"},
    ["RetrieveAPIView"] = {"GET"},
    ["UpdateAPIView"] = {"PUT", "PATCH"},
    ["DestroyAPIView"] = {"DELETE"},
    ["ListCreateAPIView"] = {"GET", "POST"},
    ["RetrieveUpdateAPIView"] = {"GET", "PUT", "PATCH"},
    ["RetrieveDestroyAPIView"] = {"GET", "DELETE"},
    ["RetrieveUpdateDestroyAPIView"] = {"GET", "PUT", "PATCH", "DELETE"},

    -- ViewSet patterns
    ["ViewSet"] = {"GET", "POST", "PUT", "PATCH", "DELETE"},
    ["ModelViewSet"] = {"GET", "POST", "PUT", "PATCH", "DELETE"},
    ["ReadOnlyModelViewSet"] = {"GET"},
  }

  -- Check for CBV patterns
  for pattern, methods in pairs(cbv_patterns) do
    if view_name:match(pattern) then
      return methods
    end
  end

  -- Default for function-based views or unknown patterns
  return {"GET", "POST", "PUT", "PATCH", "DELETE"}
end

-- Clean and normalize URL path
---@param path string Raw URL path from Django
---@return string cleaned_path Normalized path
function M.normalize_path(path)
  -- Remove leading/trailing whitespace
  path = path:gsub("^%s+", ""):gsub("%s+$", "")

  -- Ensure leading slash
  if not path:match("^/") then
    path = "/" .. path
  end

  -- Convert Django URL parameters to readable format
  path = path:gsub("<(%w+):(%w+)>", "{%2}")  -- <int:id> -> {id}
  path = path:gsub("<(%w+)>", "{%1}")       -- <slug> -> {slug}

  -- Handle regex patterns (basic cleanup)
  path = path:gsub("%(%?P<(%w+)>[^%)]+%)", "{%1}")  -- (?P<name>...) -> {name}

  return path
end

return M