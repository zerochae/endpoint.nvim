return {
  file_patterns = { "**/*.rb" },
  exclude_patterns = { "**/tmp/**", "**/log/**" },
  detection_files = { "Gemfile", "config/routes.rb" },
  patterns = {
    get = { "get\\s+['\"]", "def\\s+show", "def\\s+index" },
    post = { "post\\s+['\"]", "def\\s+create" },
    put = { "put\\s+['\"]", "patch\\s+['\"]", "def\\s+update" },
    delete = { "delete\\s+['\"]", "def\\s+destroy" },
    patch = { "patch\\s+['\"]", "def\\s+update" },
    all = { "get\\s+", "post\\s+", "put\\s+", "patch\\s+", "delete\\s+", "def\\s+" },
  },
}
