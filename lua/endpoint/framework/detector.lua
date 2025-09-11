local registry = require "endpoint.core.registry"

local M = {}

-- Get the current working directory (project root)
local function get_project_root()
  return vim.fn.getcwd()
end

-- Check if a file exists
local function file_exists(filepath)
  local stat = vim.loop.fs_stat(filepath)
  return stat ~= nil and stat.type == "file"
end

-- Check if any detection files exist in the project root
local function check_detection_files(root_path, detection_files)
  for _, file in ipairs(detection_files) do
    local full_path = root_path .. "/" .. file
    if file_exists(full_path) then
      return true
    end
  end
  return false
end

-- Special check for Node.js projects (NestJS vs Express)
local function detect_nodejs_framework(root_path)
  local package_json_path = root_path .. "/package.json"
  if not file_exists(package_json_path) then
    return nil
  end

  -- Read package.json and check dependencies
  local ok, package_content = pcall(vim.fn.readfile, package_json_path)
  if not ok then
    return nil
  end

  local content_str = table.concat(package_content, "\n")

  -- Check for NestJS dependencies
  if content_str:match "@nestjs/" then
    return "nestjs"
  end

  -- Check for Express dependencies
  if content_str:match '"express"' then
    return "express"
  end

  return nil
end

-- Special check for Python projects (FastAPI vs Django)
local function detect_python_framework(root_path)
  local pyproject_path = root_path .. "/pyproject.toml"
  local requirements_path = root_path .. "/requirements.txt"
  
  -- Check pyproject.toml first for FastAPI
  if file_exists(pyproject_path) then
    local ok, pyproject_content = pcall(vim.fn.readfile, pyproject_path)
    if ok then
      local content_str = table.concat(pyproject_content, "\n")
      -- Check for FastAPI in dependencies
      if content_str:match "fastapi" then
        return "fastapi"
      end
      -- Check for Django in dependencies
      if content_str:match "django" then
        return "django"
      end
    end
  end
  
  -- Check requirements.txt
  if file_exists(requirements_path) then
    local ok, requirements_content = pcall(vim.fn.readfile, requirements_path)
    if ok then
      local content_str = table.concat(requirements_content, "\n")
      -- Check for FastAPI first (more specific)
      if content_str:match "fastapi" then
        return "fastapi"
      end
      -- Check for Django
      if content_str:match "django" then
        return "django"
      end
    end
  end
  
  -- Check for Django-specific files
  if file_exists(root_path .. "/manage.py") then
    return "django"
  end
  
  return nil
end

-- Auto-detect framework based on project files
local function auto_detect_framework(root_path, frameworks_config)
  -- Special handling for Node.js frameworks
  local nodejs_framework = detect_nodejs_framework(root_path)
  if nodejs_framework then
    return nodejs_framework
  end
  
  -- Special handling for Python frameworks  
  local python_framework = detect_python_framework(root_path)
  if python_framework then
    return python_framework
  end
  
  -- Standard detection for other frameworks
  for framework_name, framework_config in pairs(frameworks_config) do
    if framework_name ~= "nestjs" and framework_name ~= "express" 
       and framework_name ~= "fastapi" and framework_name ~= "django" then
      if check_detection_files(root_path, framework_config.detection_files) then
        return framework_name
      end
    end
  end

  -- If no framework detected, return nil instead of defaulting
  return nil
end

-- Check if current path matches any framework_paths patterns
local function check_framework_paths(current_path, framework_paths)
  for path_pattern, framework in pairs(framework_paths) do
    -- Simple wildcard matching (* at the end)
    if path_pattern:sub(-1) == "*" then
      local pattern_prefix = path_pattern:sub(1, -2)
      if current_path:sub(1, #pattern_prefix) == pattern_prefix then
        return framework
      end
    else
      -- Exact path matching
      if current_path == path_pattern then
        return framework
      end
    end
  end
  return nil
end

-- Main function to detect the current framework
function M.detect_framework(config)
  local root_path = get_project_root()

  -- First check framework_paths for explicit overrides
  if config.framework_paths and next(config.framework_paths) then
    local override_framework = check_framework_paths(root_path, config.framework_paths)
    if override_framework then
      if config.debug then
        vim.notify(
          "Framework override detected: " .. override_framework .. " for path: " .. root_path,
          vim.log.levels.INFO
        )
      end
      return override_framework
    end
  end

  -- If framework is explicitly set (not "auto"), use it
  if config.framework and config.framework ~= "auto" then
    if config.debug then
      vim.notify("Using explicitly configured framework: " .. config.framework, vim.log.levels.INFO)
    end
    return config.framework
  end

  -- Auto-detect framework using dynamic config
  local frameworks_config = registry.build_frameworks_config()
  local detected_framework = auto_detect_framework(root_path, frameworks_config)

  if detected_framework then
    if config.debug then
      vim.notify(
        "Auto-detected framework: " .. detected_framework .. " for project: " .. root_path,
        vim.log.levels.INFO
      )
    end
    return detected_framework
  else
    if config.debug then
      vim.notify("No framework detected for project: " .. root_path, vim.log.levels.WARN)
    end
    return nil
  end
end

-- Get framework-specific configuration
function M.get_framework_config(config, framework_name)
  local framework_config = registry.get_framework_config(framework_name)
  if not framework_config then
    if config.debug then
      vim.notify("Unknown framework: " .. framework_name, vim.log.levels.WARN)
    end
  end

  return framework_config
end

-- Get current framework and its configuration
function M.get_current_framework_config(config)
  local framework_name = M.detect_framework(config)
  if not framework_name then
    error "No framework detected. Please specify a framework in your configuration."
  end

  local framework_config = M.get_framework_config(config, framework_name)
  return framework_name, framework_config
end

return M
