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
      "match\\s+['\"].*via:\\s*\\[.*:get.*\\]",
      -- Documentation patterns like Spring's @GetMapping
      "@api\\s*\\{.*get.*\\}",
      "@route.*GET",
      "@method.*GET",
      "# GET\\s+/",
      -- OAS Rails documentation patterns
      "@summary.*Get",
      "@summary.*List",
      "@summary.*Show",
      "@summary.*Retrieve",
      "def\\s+\\w+.*@summary"
    },
    post = { 
      "post\\s+['\"]", 
      "def\\s+create", 
      "resources\\s+:", 
      "match\\s+['\"].*via:\\s*\\[.*:post.*\\]",
      "@api\\s*\\{.*post.*\\}",
      "@route.*POST", 
      "@method.*POST",
      "# POST\\s+/",
      -- OAS Rails documentation patterns
      "@summary.*Create",
      "@summary.*Login",
      "@summary.*Post",
      "@request_body"
    },
    put = { 
      "put\\s+['\"]", 
      "def\\s+update", 
      "resources\\s+:", 
      "match\\s+['\"].*via:\\s*\\[.*:put.*\\]",
      "@api\\s*\\{.*put.*\\}",
      "@route.*PUT",
      "@method.*PUT", 
      "# PUT\\s+/",
      -- OAS Rails documentation patterns  
      "@summary.*Update",
      "@summary.*Put"
    },
    delete = { 
      "delete\\s+['\"]", 
      "def\\s+destroy", 
      "resources\\s+:", 
      "match\\s+['\"].*via:\\s*\\[.*:delete.*\\]",
      "@api\\s*\\{.*delete.*\\}",
      "@route.*DELETE",
      "@method.*DELETE",
      "# DELETE\\s+/",
      -- OAS Rails documentation patterns
      "@summary.*Delete",
      "@summary.*Remove",
      "@summary.*Destroy"
    },
    patch = { 
      "patch\\s+['\"]", 
      "def\\s+update", 
      "resources\\s+:", 
      "match\\s+['\"].*via:\\s*\\[.*:patch.*\\]",
      "@api\\s*\\{.*patch.*\\}", 
      "@route.*PATCH",
      "@method.*PATCH",
      "# PATCH\\s+/",
      -- OAS Rails documentation patterns
      "@summary.*Update",
      "@summary.*Patch"
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
