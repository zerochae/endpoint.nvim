# Endpoint.nvim - Spring Framework Path Extraction Fixed

This PR fixes the Spring framework path extraction bug where @GetMapping without parentheses was incorrectly extracting values from @PathVariable annotations.

## Changes:
- Fixed class selection logic to find outermost public controller class
- Added check for parentheses in method mapping extraction  
- Added comprehensive test cases for the bug fix
- All 14 Spring framework tests now pass

The test.java and test.md files have been completely removed from git history.
