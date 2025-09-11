return {
  file_patterns = { "**/*.rb" },
  exclude_patterns = {"**/tmp/**", "**/log/**", "**/vendor/**"},
  detection_files = { "Gemfile", "config/application.rb" },
  
  -- Rails display mode: "native" shows Rails method names (show, index, etc), 
  -- "restful" shows HTTP methods (GET, POST, etc)
  display_mode = "native", -- or "restful"
  
  -- Simple controller method patterns - no routes.rb confusion
  patterns = {
    get = { 
      "def\\s+(show|index|new|edit)"
    },
    post = { 
      "def\\s+create"
    },
    put = { 
      "def\\s+update"
    },
    delete = { 
      "def\\s+destroy"
    },
    patch = { 
      "def\\s+update"
    },
  },
  
  -- Rails method to HTTP method mapping
  rails_methods = {
    index = "GET",
    show = "GET", 
    new = "GET",
    edit = "GET",
    create = "POST",
    update = { "PUT", "PATCH" },
    destroy = "DELETE"
  },
  -- Rails specific configuration
  controller_patterns = {
    "class\\s+(\\w+)Controller",
    "def\\s+(\\w+)",
  },
  route_patterns = {
    "get\\s+[\"']([^\"']*)[\"']",
    "post\\s+[\"']([^\"']*)[\"']",
    "put\\s+[\"']([^\"']*)[\"']",
    "patch\\s+[\"']([^\"']*)[\"']",
    "delete\\s+[\"']([^\"']*)[\"']",
    "resources\\s+:(\\w+)",
    "resource\\s+:(\\w+)",
  },
}
