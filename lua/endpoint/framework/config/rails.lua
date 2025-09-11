return {
  file_patterns = { "**/*.rb" },
  exclude_patterns = {"**/tmp/**", "**/log/**", "**/vendor/**"},
  detection_files = { "Gemfile", "config/routes.rb", "config/application.rb" },
  patterns = {
    get = { 
      "def\\s+(show|index|new|edit)",
      "# GET\\s+/",
      "get\\s+['\"]",
      "resources\\s+:", 
      "resource\\s+:",
      "@route.*GET",
      "@method.*GET",
      "@summary.*Get",
      "@summary.*Show"
    },
    post = { 
      "def\\s+create",
      "# POST\\s+/",
      "post\\s+['\"]",
      "resources\\s+:", 
      "@route.*POST", 
      "@method.*POST",
      "@request_body",
      "@summary.*Create"
    },
    put = { 
      "def\\s+update", 
      "resources\\s+:", 
      "@route.*PUT",
      "@method.*PUT", 
      "# PUT\\s+/"
    },
    delete = { 
      "def\\s+destroy", 
      "resources\\s+:", 
      "@route.*DELETE",
      "@method.*DELETE",
      "# DELETE\\s+/"
    },
    patch = { 
      "def\\s+update", 
      "resources\\s+:", 
      "@route.*PATCH",
      "@method.*PATCH",
      "# PATCH\\s+/"
    },
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
