return {
  file_patterns = { "**/*.rb" },
  exclude_patterns = { 
    "**/tmp/**", 
    "**/log/**", 
    "**/vendor/**", 
    "**/node_modules/**",
    "**/coverage/**",
    "**/spec/**",
    "**/test/**"
  },
  detection_files = { "Gemfile", "config/routes.rb", "config/application.rb" },
  patterns = {
    get = { 
      "get\\s+['\"]", 
      "def\\s+(show|index|new|edit)", 
      "resources\\s+:", 
      "resource\\s+:",
      "match\\s+['\"].*via:\\s*\\[.*:get.*\\]"
    },
    post = { 
      "post\\s+['\"]", 
      "def\\s+create", 
      "resources\\s+:", 
      "match\\s+['\"].*via:\\s*\\[.*:post.*\\]"
    },
    put = { 
      "put\\s+['\"]", 
      "def\\s+update", 
      "resources\\s+:", 
      "match\\s+['\"].*via:\\s*\\[.*:put.*\\]"
    },
    delete = { 
      "delete\\s+['\"]", 
      "def\\s+destroy", 
      "resources\\s+:", 
      "match\\s+['\"].*via:\\s*\\[.*:delete.*\\]"
    },
    patch = { 
      "patch\\s+['\"]", 
      "def\\s+update", 
      "resources\\s+:", 
      "match\\s+['\"].*via:\\s*\\[.*:patch.*\\]"
    },
  },
  -- Rails specific configuration
  controller_patterns = {
    "class\\s+(\\w+)Controller",
    "def\\s+(\\w+)",
  },
  route_patterns = {
    "get\\s+['\"]([^'\"]*)['\"]",
    "post\\s+['\"]([^'\"]*)['\"]",
    "put\\s+['\"]([^'\"]*)['\"]",
    "patch\\s+['\"]([^'\"]*)['\"]",
    "delete\\s+['\"]([^'\"]*)['\"]",
    "resources\\s+:(\\w+)",
    "resource\\s+:(\\w+)",
  },
}
