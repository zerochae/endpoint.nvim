return {
  name = "phoenix",
  display_name = "Elixir Phoenix",
  language = "elixir",
  parser_type = "macro",
  detection = {
    files = { "mix.exs", "config/config.exs", "lib/*_web/router.ex" },
    dependencies = { "phoenix", "plug" },
    imports = { "use Phoenix", "import Phoenix" },
  },
  patterns = {
    macro_patterns = {
      "get%s+",
      "post%s+",
      "put%s+",
      "delete%s+",
      "patch%s+",
      "resources%s+",
    },
    method_extractors = {
      ["^%s*(get)%s+"] = "GET",
      ["^%s*(post)%s+"] = "POST",
      ["^%s*(put)%s+"] = "PUT",
      ["^%s*(delete)%s+"] = "DELETE",
      ["^%s*(patch)%s+"] = "PATCH",
    },
    path_patterns = {
      '%w+%s+["\']([^"\'])+["\']',
      'resources%s+["\']([^"\'])+["\']',
    },
  },
  config = {
    file_extensions = { "*.ex", "*.exs" },
    exclude_patterns = { "**/_build/**", "**/deps/**" },
    confidence = 0.8,
    tags = { "api", "phoenix", "elixir" },
  },
}