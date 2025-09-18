local Framework = require "endpoint.core.Framework"
local Detector = require "endpoint.core.Detector"
local route_parser = require "endpoint.parser.route_parser"

---@class endpoint.DjangoFramework : endpoint.Framework
local DjangoFramework = setmetatable({}, { __index = Framework })
DjangoFramework.__index = DjangoFramework

---Creates a new DjangoFramework instance
function DjangoFramework:new()
  local django_framework_instance = setmetatable({}, self)
  django_framework_instance.name = "django"
  django_framework_instance.config = {
    file_extensions = { "*.py" },
    exclude_patterns = { "**/__pycache__", "**/venv", "**/.venv", "**/site-packages", "**/migrations" },
    patterns = {
      GET = {
        "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(",
        "class.*View", "def\\s+get\\s*\\(", "def\\s+retrieve\\s*\\(", "def\\s+list\\s*\\("
      },
      POST = {
        "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(",
        "class.*View", "def\\s+post\\s*\\(", "def\\s+create\\s*\\("
      },
      PUT = {
        "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(",
        "class.*View", "def\\s+put\\s*\\(", "def\\s+update\\s*\\("
      },
      DELETE = {
        "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(",
        "class.*View", "def\\s+delete\\s*\\(", "def\\s+destroy\\s*\\("
      },
      PATCH = {
        "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(",
        "class.*View", "def\\s+patch\\s*\\(", "def\\s+partial_update\\s*\\("
      },
      ALL = {
        "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(",
        "class.*View", "class.*ViewSet",
        "def\\s+get\\s*\\(", "def\\s+post\\s*\\(", "def\\s+put\\s*\\(", "def\\s+patch\\s*\\(", "def\\s+delete\\s*\\(",
        "def\\s+create\\s*\\(", "def\\s+update\\s*\\(", "def\\s+destroy\\s*\\(", "def\\s+list\\s*\\(", "def\\s+retrieve\\s*\\(", "def\\s+partial_update\\s*\\("
      }
    },
    search_options = { "--type", "py" }
  }

  django_framework_instance:_validate_config()
  django_framework_instance:_initialize()
  ---@cast django_framework_instance DjangoFramework
  return django_framework_instance
end

---Validates the framework configuration
function DjangoFramework:_validate_config()
  if not self.name then
    error("Framework name is required")
  end

  if not self.config.file_extensions then
    self.config.file_extensions = { "*.*" }
  end

  if not self.config.exclude_patterns then
    self.config.exclude_patterns = {}
  end
end

---Sets up detection and parsing strategies for Django
function DjangoFramework:_initialize()
  -- Setup detector using backup logic patterns
  self.detector = dependency_detector:new(
    { "django", "Django" },
    { "manage.py", "settings.py", "requirements.txt", "pyproject.toml", "setup.py", "Pipfile" },
    "django_dependency_detection"
  )

  -- Setup route parser with comprehensive Django patterns from backup
  local django_route_patterns = {
    ["url_pattern"] = { "path\\s*\\(", "re_path\\s*\\(", "url\\s*\\(" },
    ["include_pattern"] = { "include\\s*\\(" },
    ["view_method"] = { "def\\s+get\\s*\\(", "def\\s+post\\s*\\(", "def\\s+put\\s*\\(", "def\\s+patch\\s*\\(", "def\\s+delete\\s*\\(" },
    ["viewset_action"] = { "def\\s+list\\s*\\(", "def\\s+create\\s*\\(", "def\\s+retrieve\\s*\\(", "def\\s+update\\s*\\(", "def\\s+destroy\\s*\\(", "def\\s+partial_update\\s*\\(" },
    ["view_class"] = { "class.*View", "class.*ViewSet" },
    ["function_view"] = { "def\\s+[%w_]+\\s*\\(" }
  }

  local django_path_extraction_patterns = {
    'r?["\']([^"\']+)["\']',   -- path("users/", ...)
    "r?'([^']+)'",            -- path('users/', ...)
    'r?"([^"]+)"',            -- re_path(r"^users/$", ...)
  }

  local django_route_processors = {
    ["url_pattern"] = self._process_django_url_pattern,
    ["include_pattern"] = self._process_django_include,
    ["view_method"] = self._process_django_view_method,
    ["viewset_action"] = self._process_django_viewset_action,
    ["view_class"] = self._process_django_view_class,
    ["function_view"] = self._process_django_function_view
  }

  self.parser = route_parser:new(
    django_route_patterns,
    django_path_extraction_patterns,
    django_route_processors,
    "django_route_parsing"
  )

  -- Add include processor
  self.parser:add_route_patterns("include_pattern", { "include\\s*\\(" })
end

---Processes Django URL patterns (path, re_path, url) using backup logic
function DjangoFramework._process_django_url_pattern(parser, content, file_path, line_number, column, endpoint_path, http_method)
  -- Extract URL pattern from content
  local url_path = content:match 'path%s*%(%s*["\']([^"\']*)["\']'
    or content:match 're_path%s*%(%s*r?["\']([^"\']+)["\']'
    or content:match 'url%s*%(%s*r?["\']([^"\']+)["\']'

  if not url_path then
    return nil
  end

  -- Extract view reference
  local view_ref = content:match "views%.([%w_]+)" or content:match "([%w_]+)%.as_view"
  if not view_ref then
    return nil
  end

  -- Determine app prefix
  local app_name = file_path:match "([%w_]+)/urls%.py$"
  local app_prefix = ""
  if app_name then
    app_prefix = DjangoFramework._extract_app_prefix(app_name)
  end

  -- Clean and combine paths
  local cleaned_path = DjangoFramework._clean_django_path(url_path)
  local full_path = app_prefix .. cleaned_path

  -- For URL patterns, determine method based on view type or default to GET
  local method = http_method or "GET"

  return {
    method = method,
    endpoint_path = full_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = method .. " " .. full_path,
    confidence = 0.9,
    tags = { "python", "django", "url_pattern" },
    metadata = {
      framework_version = "django",
      language = "python",
      view_reference = view_ref,
      route_type = "url_pattern",
      app_prefix = app_prefix,
      parser = "django_route_parsing"
    }
  }
end

---Processes Django view method implementations (get, post, etc.)
function DjangoFramework._process_django_view_method(parser, content, file_path, line_number, column, endpoint_path, http_method)
  -- Filter out class definitions
  if content:match "^%s*class%s+[%w_]+.*:" then
    return nil
  end

  -- Extract method name from view method implementation
  local method_name
  if content:match "^%s*def%s+get%s*%(" then
    method_name = "get"
  elseif content:match "^%s*def%s+post%s*%(" then
    method_name = "post"
  elseif content:match "^%s*def%s+put%s*%(" then
    method_name = "put"
  elseif content:match "^%s*def%s+patch%s*%(" then
    method_name = "patch"
  elseif content:match "^%s*def%s+delete%s*%(" then
    method_name = "delete"
  else
    return nil
  end

  -- Only process if in views.py or viewsets.py
  if not (file_path:match "views%.py$" or file_path:match "viewsets%.py$") then
    return nil
  end

  local http_method_name = DjangoFramework._convert_to_http_method(method_name, file_path)
  local class_name = DjangoFramework._find_parent_class(file_path, line_number)

  if class_name then
    local url_path = DjangoFramework._find_url_for_view(class_name, file_path)
    if url_path then
      return {
        method = http_method_name,
        endpoint_path = url_path,
        file_path = file_path,
        line_number = line_number,
        column = column,
        display_value = http_method_name .. " " .. url_path,
        confidence = 0.9,
        tags = { "python", "django", "view_method" },
        metadata = {
          framework_version = "django",
          language = "python",
          class_name = class_name,
          method_name = method_name,
          route_type = "view_method",
          parser = "django_route_parsing"
        }
      }
    end
  end

  return nil
end

---Processes Django ViewSet action methods (list, create, retrieve, etc.)
function DjangoFramework._process_django_viewset_action(parser, content, file_path, line_number, column, endpoint_path, http_method)
  -- Extract ViewSet action method name
  local action_name
  if content:match "^%s*def%s+list%s*%(" then
    action_name = "list"
  elseif content:match "^%s*def%s+create%s*%(" then
    action_name = "create"
  elseif content:match "^%s*def%s+retrieve%s*%(" then
    action_name = "retrieve"
  elseif content:match "^%s*def%s+update%s*%(" then
    action_name = "update"
  elseif content:match "^%s*def%s+destroy%s*%(" then
    action_name = "destroy"
  elseif content:match "^%s*def%s+partial_update%s*%(" then
    action_name = "partial_update"
  else
    return nil
  end

  -- Only process ViewSet files
  if not (file_path:match "viewsets%.py$") then
    return nil
  end

  local http_method_name = DjangoFramework._convert_to_http_method(action_name, file_path)
  local class_name = DjangoFramework._find_parent_class(file_path, line_number)

  if class_name then
    local urls = DjangoFramework._find_router_urls_for_viewset(class_name, file_path)
    local url_path = #urls > 0 and urls[1] or DjangoFramework._build_viewset_fallback_url(class_name, file_path)

    return {
      method = http_method_name,
      endpoint_path = url_path,
      file_path = file_path,
      line_number = line_number,
      column = column,
      display_value = http_method_name .. " " .. url_path,
      confidence = 0.85,
      tags = { "python", "django", "viewset_action" },
      metadata = {
        framework_version = "django",
        language = "python",
        class_name = class_name,
        action_name = action_name,
        route_type = "viewset_action",
        parser = "django_route_parsing"
      }
    }
  end

  return nil
end

---Processes Django view class definitions
function DjangoFramework._process_django_view_class(parser, content, file_path, line_number, column, endpoint_path, http_method)
  local class_name = content:match "^%s*class%s+([%w_]+)%s*%("
  if not class_name then
    return nil
  end

  -- Only process view files
  if not (file_path:match "views%.py$" or file_path:match "viewsets%.py$") then
    return nil
  end

  -- Handle ViewSets differently from regular views
  if file_path:match "viewsets%.py$" or class_name:match "ViewSet$" then
    local urls = DjangoFramework._find_router_urls_for_viewset(class_name, file_path)
    local url_path = #urls > 0 and urls[1] or DjangoFramework._build_viewset_fallback_url(class_name, file_path)
    local methods = DjangoFramework._analyze_viewset_methods(class_name, file_path, line_number)
    local primary_method = DjangoFramework._select_primary_method(methods, http_method or "GET")

    return {
      method = primary_method,
      endpoint_path = url_path,
      file_path = file_path,
      line_number = line_number,
      column = column,
      display_value = primary_method .. " " .. url_path,
      confidence = 0.8,
      tags = { "python", "django", "viewset_class" },
      metadata = {
        framework_version = "django",
        language = "python",
        class_name = class_name,
        route_type = "viewset_class",
        supported_methods = methods,
        parser = "django_route_parsing"
      }
    }
  else
    -- Regular class-based view
    local url_path = DjangoFramework._find_url_for_view(class_name, file_path)
    if url_path then
      local methods = DjangoFramework._analyze_view_methods(class_name, file_path)
      local primary_method = DjangoFramework._select_primary_method(methods, http_method or "GET")

      return {
        method = primary_method,
        endpoint_path = url_path,
        file_path = file_path,
        line_number = line_number,
        column = column,
        display_value = primary_method .. " " .. url_path,
        confidence = 0.85,
        tags = { "python", "django", "view_class" },
        metadata = {
          framework_version = "django",
          language = "python",
          class_name = class_name,
          route_type = "view_class",
          supported_methods = methods,
          parser = "django_route_parsing"
        }
      }
    end
  end

  return nil
end

---Processes Django function-based views
function DjangoFramework._process_django_function_view(parser, content, file_path, line_number, column, endpoint_path, http_method)
  local function_name = content:match "^%s*def%s+([%w_]+)%s*%("
  if not function_name then
    return nil
  end

  -- Only process view files
  if not (file_path:match "views%.py$" or file_path:match "viewsets%.py$") then
    return nil
  end

  -- Skip Django built-in HTTP method handlers
  if function_name:match "^(get|post|put|patch|delete|head|options|trace)$" then
    return nil
  end

  local url_path = DjangoFramework._find_url_for_function(function_name, file_path)
  if url_path then
    local methods = DjangoFramework._analyze_function_view_methods(function_name, file_path, line_number)
    local primary_method = DjangoFramework._select_primary_method(methods, http_method or "GET")

    return {
      method = primary_method,
      endpoint_path = url_path,
      file_path = file_path,
      line_number = line_number,
      column = column,
      display_value = primary_method .. " " .. url_path,
      confidence = 0.8,
      tags = { "python", "django", "function_view" },
      metadata = {
        framework_version = "django",
        language = "python",
        function_name = function_name,
        route_type = "function_view",
        supported_methods = methods,
        parser = "django_route_parsing"
      }
    }
  end

  return nil
end

---Processes Django include() patterns
function DjangoFramework._process_django_include(parser, content, file_path, line_number, column, endpoint_path, http_method)
  local include_module = content:match('include\\s*\\(["\']([^"\']+)["\']')
  local cleaned_path = DjangoFramework._clean_django_path(endpoint_path)

  return {
    method = "INCLUDE",
    endpoint_path = cleaned_path,
    file_path = file_path,
    line_number = line_number,
    column = column,
    display_value = "INCLUDE " .. cleaned_path,
    confidence = 0.9,
    tags = { "python", "django", "include" },
    metadata = {
      framework_version = "django",
      language = "python",
      include_module = include_module,
      route_type = "include",
      parser = "django_route_parsing"
    }
  }
end

---Cleans Django path patterns
function DjangoFramework._clean_django_path(path)
  if not path then return "/" end

  -- Remove regex anchors
  local cleaned = path:gsub("^%^", ""):gsub("%$$", "")

  -- Convert Django path parameters <type:name> to {name}
  cleaned = cleaned:gsub("<([^:>]+):([^>]+)>", "{%2}")

  -- Convert regex named groups (?P<name>pattern) to {name}
  cleaned = cleaned:gsub("%%(%?P<([^>]+)>[^)]*%%)", "{%1}")

  -- Ensure path starts with /
  if not cleaned:match("^/") then
    cleaned = "/" .. cleaned
  end

  -- Remove trailing slash for consistency (except root)
  if cleaned ~= "/" and cleaned:match("/$") then
    cleaned = cleaned:gsub("/$", "")
  end

  return cleaned
end

---Detects if Django is present in the current project
function DjangoFramework:detect()
  if not self.detector then
    self:_initialize()
  end
  return self.detector and self.detector:is_target_detected() or false
end

---Parses Django content to extract endpoint information
function DjangoFramework:parse(content, file_path, line_number, column)
  -- Only process if this looks like Django code
  if not (content:match("urlpatterns") or content:match("path%s*%(") or
          content:match("re_path%s*%(") or content:match("url%s*%(") or
          content:match("class.*View") or content:match("def%s+[%w_]+%s*%(")) then
    return nil
  end

  -- Direct parsing approach - try URL patterns first
  local result = DjangoFramework._process_django_url_pattern(nil, content, file_path, line_number, column, nil, nil)
  if result then
    return result
  end

  -- Fallback to parser
  if not self.parser then
    self:_initialize()
  end

  local parsed_endpoint = self.parser and self.parser:parse_content(content, file_path, line_number, column)

  if parsed_endpoint then
    -- Enhance with additional Django-specific metadata
    if not parsed_endpoint.tags then
      parsed_endpoint.tags = {}
    end

    -- Ensure Django tags are present
    local has_python = false
    local has_django = false
    for _, tag in ipairs(parsed_endpoint.tags) do
      if tag == "python" then has_python = true end
      if tag == "django" then has_django = true end
    end

    if not has_python then table.insert(parsed_endpoint.tags, "python") end
    if not has_django then table.insert(parsed_endpoint.tags, "django") end

    -- Set framework metadata
    parsed_endpoint.metadata = parsed_endpoint.metadata or {}
    parsed_endpoint.metadata.framework_version = "django"
    parsed_endpoint.metadata.language = "python"
  end

  return parsed_endpoint
end

---Gets the search command for finding all endpoints
function DjangoFramework:get_search_cmd()
  if not self.config.patterns then
    error("Patterns not configured for framework: " .. self.name)
  end

  local rg = require "endpoint.utils.rg"

  local search_options = {
    method_patterns = self.config.patterns,
    file_globs = self.config.file_extensions,
    exclude_globs = self.config.exclude_patterns,
    extra_flags = self.config.search_options or {}
  }

  return rg.create_command(search_options)
end

---Main template method for scanning endpoints
function DjangoFramework:scan(options)
  options = options or {}

  local log = require "endpoint.utils.log"
  log.framework_debug("Starting scan with framework: " .. self.name)

  if not self:detect() then
    log.framework_debug("Framework not detected: " .. self.name)
    return {}
  end

  -- Get search command and execute it
  local search_cmd = self:get_search_cmd()
  local handle = io.popen(search_cmd)
  local result = handle:read("*a")
  handle:close()

  local endpoints = {}
  for line in result:gmatch("[^\n]+") do
    local file_path, line_number, column, content = line:match("([^:]+):(%d+):(%d+):(.*)")
    if file_path and line_number and column and content then
      local endpoint = self:parse(content, file_path, tonumber(line_number), tonumber(column))
      if endpoint then
        table.insert(endpoints, endpoint)
      end
    end
  end

  log.framework_debug("Found " .. #endpoints .. " endpoints with " .. self.name)
  return endpoints
end

-- Helper functions from backup logic adapted for new structure

---Extract app prefix from main urls.py structure
function DjangoFramework._extract_app_prefix(app_name)
  local main_urls_files = { "myproject/urls.py", "*/urls.py", "urls.py" }

  for _, main_urls_pattern in ipairs(main_urls_files) do
    local possible_files = {}
    if main_urls_pattern:match "%*" then
      possible_files = vim.fn.glob(main_urls_pattern, false, true)
    else
      if vim.fn.filereadable(main_urls_pattern) == 1 then
        table.insert(possible_files, main_urls_pattern)
      end
    end

    for _, main_urls_file in ipairs(possible_files) do
      if vim.fn.filereadable(main_urls_file) == 1 then
        local main_content = vim.fn.readfile(main_urls_file)
        for _, main_line in ipairs(main_content) do
          if main_line:match(app_name .. "%.urls") then
            local prefix = main_line:match 'path%s*%(%s*["\']([^"\']*)["\']'
            if prefix then
              return "/" .. prefix:gsub("/$", "")
            end
          end
        end
      end
    end
  end
  return ""
end

---Find URL pattern for a specific view class
function DjangoFramework._find_url_for_view(view_name, current_file)
  if current_file:match "views%.py$" or current_file:match "viewsets%.py$" then
    local urls_file = current_file:gsub("views%.py$", "urls.py"):gsub("viewsets%.py$", "urls.py")
    if vim.fn.filereadable(urls_file) == 1 then
      local content = vim.fn.readfile(urls_file)
      local app_name = current_file:match "([%w_]+)/views%.py$" or current_file:match "([%w_]+)/viewsets%.py$"
      local app_prefix = app_name and DjangoFramework._extract_app_prefix(app_name) or ""

      for _, line in ipairs(content) do
        if line:match(view_name) then
          local path = line:match 'path%s*%(%s*["\']([^"\']+)["\']'
          if path then
            local normalized_path = DjangoFramework._clean_django_path(path)
            return app_prefix .. normalized_path
          end
        end
      end
    end
  end
  return nil
end

---Find URL pattern for a function-based view
function DjangoFramework._find_url_for_function(function_name, file_path)
  if file_path:match "views%.py$" or file_path:match "viewsets%.py$" then
    local urls_file = file_path:gsub("views%.py$", "urls.py"):gsub("viewsets%.py$", "urls.py")
    if vim.fn.filereadable(urls_file) == 1 then
      local content = vim.fn.readfile(urls_file)
      local app_name = file_path:match "([%w_]+)/views%.py$" or file_path:match "([%w_]+)/viewsets%.py$"
      local app_prefix = app_name and DjangoFramework._extract_app_prefix(app_name) or ""

      for _, line in ipairs(content) do
        if line:match("views%." .. function_name) then
          local path = line:match 'path%s*%(%s*["\']([^"\']*)["\']'
            or line:match 're_path%s*%(%s*r?["\']([^"\']+)["\']'
            or line:match 'url%s*%(%s*r?["\']([^"\']+)["\']'
          if path then
            local normalized_path = DjangoFramework._clean_django_path(path)
            return app_prefix .. normalized_path
          end
        end
      end
    end
  end
  return nil
end

---Find parent class for a method at given line number
function DjangoFramework._find_parent_class(file_path, line_number)
  if vim.fn.filereadable(file_path) == 1 then
    local content = vim.fn.readfile(file_path)
    for i = line_number - 1, 1, -1 do
      local line = content[i]
      local class_name = line:match "^%s*class%s+([%w_]+)"
      if class_name then
        return class_name
      end
    end
  end
  return nil
end

---Convert method names to HTTP methods
function DjangoFramework._convert_to_http_method(method_name, file_path)
  local method_lower = method_name:lower()

  if method_lower == "get" or method_lower == "list" or method_lower == "retrieve" then
    return "GET"
  elseif method_lower == "post" or method_lower == "create" then
    return "POST"
  elseif method_lower == "put" or method_lower == "update" then
    return "PUT"
  elseif method_lower == "patch" or method_lower == "partial_update" then
    return "PATCH"
  elseif method_lower == "delete" or method_lower == "destroy" then
    return "DELETE"
  else
    return method_name:upper()
  end
end

---Analyze what HTTP methods a view supports
function DjangoFramework._analyze_view_methods(view_name, file_path)
  local methods = {}
  local views_file = file_path:gsub("urls%.py$", "views.py")

  if vim.fn.filereadable(views_file) == 1 then
    local content = vim.fn.readfile(views_file)
    local in_class = false

    for _, line in ipairs(content) do
      if line:match("class%s+" .. view_name) then
        in_class = true
      elseif in_class and line:match "def%s+(get|post|put|patch|delete)%s*%(" then
        local method = line:match "def%s+([%w]+)%s*%("
        if method then
          table.insert(methods, method:upper())
        end
      elseif in_class and line:match "^class%s+" and not line:match(view_name) then
        in_class = false
      end
    end
  end

  if #methods == 0 then
    if view_name:match "List" then
      methods = { "GET", "POST" }
    elseif view_name:match "Detail" then
      methods = { "GET", "PUT", "PATCH", "DELETE" }
    elseif view_name:match "Create" then
      methods = { "POST" }
    elseif view_name:match "Update" then
      methods = { "PUT", "PATCH" }
    elseif view_name:match "Delete" then
      methods = { "DELETE" }
    else
      methods = { "GET" }
    end
  end

  return methods
end

---Analyze function-based view methods
function DjangoFramework._analyze_function_view_methods(function_name, file_path, line_number)
  local methods = {}

  if vim.fn.filereadable(file_path) == 1 then
    local content = vim.fn.readfile(file_path)
    local in_function = false

    for i = line_number, #content do
      local line = content[i]

      if line:match("def%s+" .. function_name .. "%s*%(") then
        in_function = true
      elseif in_function and (line:match "^def%s+" or line:match "^class%s+") then
        break
      elseif in_function then
        if line:match 'request%.method%s*==%s*["\']GET["\']' then
          table.insert(methods, "GET")
        elseif line:match 'request%.method%s*==%s*["\']POST["\']' then
          table.insert(methods, "POST")
        elseif line:match 'request%.method%s*==%s*["\']PUT["\']' then
          table.insert(methods, "PUT")
        elseif line:match 'request%.method%s*==%s*["\']PATCH["\']' then
          table.insert(methods, "PATCH")
        elseif line:match 'request%.method%s*==%s*["\']DELETE["\']' then
          table.insert(methods, "DELETE")
        end
      end
    end
  end

  if #methods == 0 then
    if function_name:match "list" or function_name:match "get" or function_name:match "detail" then
      methods = { "GET" }
    elseif function_name:match "create" or function_name:match "add" then
      methods = { "POST" }
    elseif function_name:match "update" then
      methods = { "PUT", "PATCH" }
    elseif function_name:match "delete" or function_name:match "remove" then
      methods = { "DELETE" }
    else
      methods = { "GET" }
    end
  end

  return methods
end

---Analyze ViewSet methods
function DjangoFramework._analyze_viewset_methods(viewset_name, file_path, line_number)
  local methods = {}

  if vim.fn.filereadable(file_path) == 1 then
    local content = vim.fn.readfile(file_path)
    local in_viewset = false

    for i = line_number, #content do
      local line = content[i]

      if line:match("class%s+" .. viewset_name) then
        in_viewset = true
      elseif in_viewset and line:match "^class%s+" and not line:match("class%s+" .. viewset_name) then
        break
      elseif in_viewset then
        if line:match "def%s+list%s*%(" then
          table.insert(methods, "GET")
        elseif line:match "def%s+create%s*%(" then
          table.insert(methods, "POST")
        elseif line:match "def%s+retrieve%s*%(" then
          table.insert(methods, "GET")
        elseif line:match "def%s+update%s*%(" then
          table.insert(methods, "PUT")
        elseif line:match "def%s+partial_update%s*%(" then
          table.insert(methods, "PATCH")
        elseif line:match "def%s+destroy%s*%(" then
          table.insert(methods, "DELETE")
        end
      end
    end
  end

  if #methods == 0 then
    methods = { "GET", "POST", "PUT", "PATCH", "DELETE" }
  end

  return methods
end

---Find router URLs for ViewSet
function DjangoFramework._find_router_urls_for_viewset(viewset_name, file_path)
  local urls = {}
  local main_urls_files = { "myproject/urls.py", "*/urls.py", "urls.py" }

  for _, main_urls_pattern in ipairs(main_urls_files) do
    local possible_files = {}
    if main_urls_pattern:match "%*" then
      possible_files = vim.fn.glob(main_urls_pattern, false, true)
    else
      if vim.fn.filereadable(main_urls_pattern) == 1 then
        table.insert(possible_files, main_urls_pattern)
      end
    end

    for _, urls_file in ipairs(possible_files) do
      if vim.fn.filereadable(urls_file) == 1 then
        local content = vim.fn.readfile(urls_file)
        local router_prefix = ""
        local viewset_route_prefix = ""

        for _, line in ipairs(content) do
          if line:match "router%.urls" then
            router_prefix = line:match 'path%s*%(%s*["\']([^"\']*)["\']' or ""
          elseif line:match "router%.register" and line:match(viewset_name) then
            viewset_route_prefix = line:match 'router%.register%s*%(%s*r?["\']([^"\']+)["\']' or ""
            break
          end
        end

        if router_prefix ~= "" and viewset_route_prefix ~= "" then
          local full_path = "/" .. router_prefix:gsub("/$", "") .. "/" .. viewset_route_prefix
          full_path = full_path:gsub("//+", "/")
          table.insert(urls, full_path)
        end
      end
    end
  end

  return urls
end

---Build ViewSet fallback URL
function DjangoFramework._build_viewset_fallback_url(class_name, file_path)
  local resource_name = class_name:gsub("ViewSet$", ""):lower()
  resource_name = resource_name:gsub("([A-Z])", function(c) return "_" .. c:lower() end):gsub("^_", "")

  local app_name = file_path:match "([%w_]+)/viewsets%.py$"
  if app_name then
    return "/" .. app_name .. "/" .. resource_name .. "/"
  end
  return "/api/" .. resource_name .. "/"
end

---Select primary HTTP method from list
function DjangoFramework._select_primary_method(methods, search_method)
  if #methods == 0 then
    return "GET"
  end

  for _, method in ipairs(methods) do
    if method == search_method then
      return method
    end
  end

  return methods[1]
end

return DjangoFramework
