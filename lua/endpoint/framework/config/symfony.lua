return {
  file_patterns = { "**/*.php" },
  exclude_patterns = { "**/vendor/**", "**/var/**", "**/public/**" },
  detection_files = { "composer.json", "symfony.lock", "config/services.yaml" },
  base_path_patterns = {
    "#%[Route%(['\"](.-)['\"]", -- Class-level Route attribute (simple match)
    "@Route%(['\"](.-)['\"]", -- Class-level Route annotation
  },
  patterns = {
    get = {
      "methods.*GET",
      "#\\[Route.*GET",
      "@Route.*GET",
    },
    post = {
      "methods.*POST",
      "#\\[Route.*POST",
      "@Route.*POST",
    },
    put = {
      "methods.*PUT",
      "#\\[Route.*PUT",
      "@Route.*PUT",
    },
    delete = {
      "methods.*DELETE",
      "#\\[Route.*DELETE",
      "@Route.*DELETE",
    },
    patch = {
      "methods.*PATCH",
      "#\\[Route.*PATCH",
      "@Route.*PATCH",
    },
  },
}
