# TODO - endpoint.nvim

## Comment Filtering Enhancement

### Problem Description
**Issue**: endpoint.nvim currently detects commented-out code as valid endpoints across all frameworks.

**Examples of problematic detection:**
```python
# FastAPI - These commented lines show up in results
# @router.delete(
#     "/{product_id}",
#     status_code=status.HTTP_204_NO_CONTENT
# )
# Results in: DELETE /{product_id} (should be ignored)
```

```csharp
// C# - These commented lines show up in results
// [HttpGet("users/{id}")]
// public async Task<User> GetUser(int id) { }
// Results in: GET /users/{id} (should be ignored)
```

```typescript
// NestJS - These commented lines show up in results
// @Get('users/:id')
// async getUser(@Param('id') id: string) { }
// Results in: GET /users/:id (should be ignored)
```

**Root cause**: ripgrep searches for patterns (e.g., `@router.get`, `[HttpGet]`, `@Get`) without considering if they're commented out.

### Current Implementation Status
- **DotNet parser**: ✅ Has `_is_commented_code()` function that filters out commented attributes (`//` and `/* */`)
- **All other parsers**: ❌ No comment filtering implemented yet

**DotNet implementation location**: `lua/endpoint/parser/dotnet_parser.lua:_is_commented_code()`

### Proposed Solution
Implement user-configurable comment filtering system:

#### Phase 1: Extend Comment Filtering to All Frameworks
- [ ] **FastAPI**: Add Python comment filtering (`#`)
- [ ] **NestJS**: Add TypeScript comment filtering (`//`, `/* */`)
- [ ] **Ktor**: Add Kotlin comment filtering (`//`, `/* */`)
- [ ] **Spring**: Add Java comment filtering (`//`, `/* */`)
- [ ] **Symfony**: Add PHP comment filtering (`//`, `/* */`, `#`)
- [ ] **Express**: Add JavaScript comment filtering (`//`, `/* */`)
- [ ] **Rails**: Add Ruby comment filtering (`#`)

#### Phase 2: Create User Configuration Option
Add configuration option to control comment filtering behavior:

```lua
-- User config example
{
  comment_filtering = {
    enabled = true,  -- Default: ignore commented endpoints
    per_language = {
      python = true,      -- FastAPI, Django
      typescript = true,  -- NestJS, Express-TS
      javascript = true,  -- Express
      csharp = true,      -- DotNet
      java = true,        -- Spring, Servlet
      kotlin = true,      -- Ktor
      php = true,         -- Symfony
      ruby = true         -- Rails
    }
  }
}
```

#### Phase 3: Implementation Details
1. **Base comment detection patterns** by language:
   - Python: `^\\s*#`
   - JavaScript/TypeScript: `^\\s*//`, `^\\s*/\\*`
   - C#/Java/Kotlin: `^\\s*//`, `^\\s*/\\*`
   - PHP: `^\\s*//`, `^\\s*/\\*`, `^\\s*#`
   - Ruby: `^\\s*#`

2. **Utility function** in base Parser class:
   ```lua
   function Parser:is_commented_line(line, language)
     -- Language-specific comment detection
   end
   ```

3. **Configuration integration**:
   - Read from user config
   - Apply filters before endpoint creation
   - Fallback to enabled=true for better UX

### Use Cases
- **Default behavior**: Clean results without commented code (recommended for most users)
- **Development mode**: Include commented code for debugging (when temporarily commenting endpoints)
- **Legacy code analysis**: See all patterns including commented ones (for codebase analysis)
- **Team preferences**: Some teams might want to see commented endpoints as "potential future endpoints"

### Benefits
- **User choice**: Flexible configuration per project/language needs
- **Clean results**: Better default experience - no confusion from dead code
- **Debugging support**: Option to see all matches when needed for troubleshooting
- **Consistent behavior**: Same logic across all frameworks (FastAPI, NestJS, Spring, etc.)

### Technical Notes
- **Implementation approach**: Extend each parser's `parse_content()` or `is_content_valid_for_parsing()` method
- **Pattern detection**: Check if the line containing the endpoint pattern starts with language-specific comment syntax
- **Configuration integration**: Hook into existing user config system in endpoint.nvim
- **Performance impact**: Minimal - just additional regex check per matched line
- **Backward compatibility**: Default to filtering enabled, so existing users get cleaner results

### Related Files to Modify
- `lua/endpoint/parser/fastapi_parser.lua` - Add Python comment filtering
- `lua/endpoint/parser/nestjs_parser.lua` - Add TypeScript/JavaScript comment filtering
- `lua/endpoint/parser/spring_parser.lua` - Add Java comment filtering
- `lua/endpoint/parser/ktor_parser.lua` - Add Kotlin comment filtering
- `lua/endpoint/parser/symfony_parser.lua` - Add PHP comment filtering
- `lua/endpoint/parser/express_parser.lua` - Add JavaScript comment filtering
- `lua/endpoint/parser/rails_parser.lua` - Add Ruby comment filtering
- User config system - Add comment filtering configuration options

---

*Created: 2024-09-24*
*Context: Discovered during FastAPI multiline testing - commented endpoints were appearing in results*
*Priority: Medium*
*Estimated effort: 2-3 sessions*
*Status: Planning phase - DotNet implementation exists as reference*