-- Go Gin Framework
local factory = require "endpoint.frameworks.base"

-- Gin patterns 정의
local gin_patterns = {
  GET = { "router%.GET", "r%.GET" },
  POST = { "router%.POST", "r%.POST" },
  PUT = { "router%.PUT", "r%.PUT" },
  DELETE = { "router%.DELETE", "r%.DELETE" },
  PATCH = { "router%.PATCH", "r%.PATCH" }
}

-- Extract path from Gin routes
local function extract_path(content)
  -- router.GET("/path"), r.POST("/path"), etc.
  local path = content:match '%.%u+%s*%(%s*["\']([^"\']+)["\']'
  return path
end

-- Extract HTTP method from Gin route
local function extract_method(content)
  local method = content:match '%.(%u+)%s*%('
  return method
end

-- Gin Framework Creation
return factory:new({
  name = "gin",
  file_extensions = { "*.go" },
  exclude_patterns = { "**/vendor/**" },
  detection = {
    files = { "go.mod", "main.go" },
    dependencies = { "github.com/gin-gonic/gin" },
    imports = { "github.com/gin-gonic/gin", "gin.Default", "gin.New" },
  },
  patterns = gin_patterns,
  parser = function(content, file_path, line_number)
    local endpoint_path = extract_path(content)
    if not endpoint_path then
      return nil, nil
    end

    local parsed_method = extract_method(content)
    if not parsed_method then
      return nil, nil
    end

    return parsed_method, endpoint_path
  end,
})