# Performance & Caching

Complete guide to endpoint.nvim's caching system and performance optimization.

## Cache Modes

endpoint.nvim provides three intelligent caching modes to balance performance and data freshness.

### None Mode (Default)

```lua
require("endpoint").setup({
  cache_mode = "none"
})
```

> [!NOTE]
> This is the default mode - always returns the most up-to-date results by scanning files in real-time.

**When to use:**
- ✅ Small projects (< 100 endpoints)
- ✅ Active development with frequent endpoint changes
- ✅ When you need guaranteed fresh results

**Performance:**
- Real-time scanning on every search
- No memory or disk usage
- Slight delay on large codebases

### Session Mode

```lua
require("endpoint").setup({
  cache_mode = "session"
})
```

> [!TIP]
> Best balance of performance and freshness for most projects. Cache persists until you close Neovim.

**When to use:**
- ✅ Medium projects (100-1000 endpoints)
- ✅ Most development workflows
- ✅ Balance of performance and freshness

**Performance:**
- First scan builds cache, subsequent searches are instant
- Memory usage: ~1-5MB for typical projects
- Cache invalidated when Neovim closes

### Persistent Mode

```lua
require("endpoint").setup({
  cache_mode = "persistent"
})
```

> [!WARNING]
> Use only for large, stable projects. Cache may become stale if you frequently add/remove endpoints.

**When to use:**
- ✅ Large projects (1000+ endpoints)
- ✅ Stable codebases with infrequent endpoint changes
- ✅ Team environments with consistent project structure

**Performance:**
- Instant loading on subsequent Neovim sessions
- Disk cache survives restarts and reboots
- Cache location: `~/.local/share/nvim/endpoint.nvim/[project-name]/`

## Cache Management

### Commands

```vim
:Endpoint ClearCache   " Clear all cached data
:Endpoint CacheStatus  " Show current cache statistics
```

> [!TIP]
> Use `:Endpoint CacheStatus` to see detailed information about your cache performance and hit rates.

### Cache Status Information

The `:Endpoint CacheStatus` command shows:

- **Cache mode**: Current caching strategy
- **Endpoints by method**: Breakdown of cached GET, POST, PUT, DELETE, PATCH endpoints
- **Cache timestamps**: When data was last updated
- **Hit/miss statistics**: Cache performance metrics
- **Memory usage**: Current cache memory footprint
- **Disk usage**: Size of persistent cache files (persistent mode only)

## Performance Optimization

### For Small Projects (< 100 endpoints)

```lua
require("endpoint").setup({
  cache_mode = "none",  -- Real-time is fast enough
  picker = "vim_ui_select", -- Lightweight picker
})
```

> [!NOTE]
> Small projects don't need caching. The overhead of cache management may actually slow things down.

### For Medium Projects (100-1000 endpoints)

```lua
require("endpoint").setup({
  cache_mode = "session", -- Perfect balance
  picker = "telescope",   -- Rich features worth the cost
})
```

> [!TIP]
> This is the sweet spot configuration for most development workflows.

### For Large Projects (1000+ endpoints)

```lua
require("endpoint").setup({
  cache_mode = "persistent", -- Essential for large codebases
  picker = "snacks",        -- Modern and efficient
})
```

> [!WARNING]
> Monitor cache freshness in large projects. Consider clearing cache after major refactoring.

### Monorepo Optimization

```lua
require("endpoint").setup({
  cache_mode = "persistent",
  -- Each project gets its own cache
})
```

> [!NOTE]
> Each project directory gets its own cache, so monorepos work efficiently without cache conflicts.

## Cache Invalidation

### Automatic Invalidation

> [!NOTE]
> endpoint.nvim automatically detects when files need re-scanning in persistent mode.

**Triggers:**
- File modifications in source directories
- New files matching framework patterns
- Project structure changes
- Configuration changes

### Manual Invalidation

```vim
:Endpoint ClearCache
```

> [!TIP]
> Clear cache after major refactoring, framework upgrades, or when results seem stale.

### Smart Invalidation (Persistent Mode)

```lua
-- Cache is automatically invalidated when:
-- 1. Source files are newer than cache
-- 2. Project structure changes
-- 3. Framework detection results change
```

## Troubleshooting Performance Issues

### Slow Searches

> [!WARNING]
> If searches are slow, check these common issues:

1. **Large project without caching**:
   ```lua
   cache_mode = "none" -- Change to "session" or "persistent"
   ```

2. **Too many files being scanned**:
   - Check exclude patterns in framework implementations
   - Verify ripgrep isn't scanning build/dist directories

3. **Complex regex patterns**:
   - Framework patterns may be too broad
   - Check ripgrep command with debug mode

### Memory Usage Issues

> [!NOTE]
> Session cache memory usage is typically 1-5MB for normal projects.

**If memory usage is high:**

1. **Check cache size**:
   ```vim
   :Endpoint CacheStatus
   ```

2. **Clear cache periodically**:
   ```vim
   :Endpoint ClearCache
   ```

3. **Use persistent mode for very large projects**:
   ```lua
   cache_mode = "persistent" -- Moves data to disk
   ```

### Stale Cache Issues

> [!TIP]
> If you're seeing outdated results, the cache may be stale.

**Solutions:**

1. **Clear cache manually**:
   ```vim
   :Endpoint ClearCache
   ```

2. **Switch to more aggressive invalidation**:
   ```lua
   cache_mode = "session" -- Instead of "persistent"
   ```

3. **Use real-time mode for active development**:
   ```lua
   cache_mode = "none" -- No caching
   ```

## Monitoring Performance

### Debug Mode

```bash
ENDPOINT_DEBUG=1 nvim -c "Endpoint All"
```

> [!NOTE]
> Debug mode shows detailed timing information for cache operations and search performance.

**Debug output includes:**
- Cache hit/miss information
- Search command execution time
- File scanning statistics
- Memory usage changes

### Benchmarking

```lua
-- Add to your config for performance monitoring
vim.g.endpoint_debug = true

-- Then check :messages after searches to see timing
```

> [!TIP]
> Use debug mode to identify performance bottlenecks in your specific project setup.

## Cache Directory Structure

### Persistent Cache Layout

```text
~/.local/share/nvim/endpoint.nvim/
├── my-spring-project/
│   ├── endpoints.json     # Cached endpoint data
│   ├── metadata.json      # Cache metadata
│   └── framework.txt      # Detected framework
├── my-nestjs-project/
│   └── ...
└── my-rails-project/
    └── ...
```

> [!NOTE]
> Each project gets its own cache directory based on the project root path.

### Cache Data Format

```json
{
  "version": "1.0",
  "framework": "spring",
  "timestamp": 1634567890,
  "endpoints": {
    "GET": [
      {
        "method": "GET",
        "endpoint_path": "/api/users",
        "file_path": "src/main/java/UserController.java",
        "line_number": 15,
        "column": 5
      }
    ]
  }
}
```

> [!WARNING]
> Don't manually edit cache files. Use `:Endpoint ClearCache` to reset if needed.

## Best Practices

### Development Workflow

1. **Start with session mode**:
   ```lua
   cache_mode = "session"
   ```

2. **Use real-time during active endpoint development**:
   ```lua
   cache_mode = "none" -- When adding many new endpoints
   ```

3. **Switch to persistent for stable projects**:
   ```lua
   cache_mode = "persistent" -- After major development phases
   ```

> [!TIP]
> You can change cache modes dynamically and restart Neovim to apply changes.

### Team Environments

> [!NOTE]
> Each developer's cache is independent. Cache settings don't affect team members.

**Recommended team setup:**
```lua
require("endpoint").setup({
  cache_mode = "session", -- Good default for all team members
  -- Let individuals optimize based on their workflow
})
```

### CI/CD Considerations

> [!WARNING]
> Don't commit cache directories to version control.

Add to `.gitignore`:
```gitignore
# endpoint.nvim cache
.endpoint-cache/
```