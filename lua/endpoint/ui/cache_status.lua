local M = {}
local fs = require "endpoint.utils.fs"

local function create_ascii_title()
  return {
    "╔═══════════════════════════════════════════════════════════╗",
    "║                      ENDPOINT.NVIM                        ║",
    "║                   Cache Status Monitor                    ║",
    "╚═══════════════════════════════════════════════════════════╝",
    "",
  }
end

local function create_section_header(title, icon)
  icon = icon or "📊"
  return {
    "┌─ " .. icon .. " " .. title .. " " .. string.rep("─", 50 - #title - 3),
    "│",
  }
end

local function create_section_footer()
  return {
    "│",
    "└" .. string.rep("─", 59),
    "",
  }
end

local function format_file_size(file_path)
  local stat = vim.loop.fs_stat(file_path)
  if not stat then
    return "0 B"
  end

  local size = stat.size
  if size < 1024 then
    return size .. " B"
  elseif size < 1024 * 1024 then
    return string.format("%.1f KB", size / 1024)
  else
    return string.format("%.1f MB", size / (1024 * 1024))
  end
end

local function get_cache_statistics()
  local cache = require "endpoint.services.cache"
  local find_table = cache.get_find_table()
  local preview_table = cache.get_preview_table()

  local stats = {
    total_files = 0,
    total_endpoints = 0,
    total_annotations = {},
    frameworks = {},
  }

  for path, path_data in pairs(find_table) do
    stats.total_files = stats.total_files + 1

    for annotation, entries in pairs(path_data) do
      if not vim.tbl_contains(stats.total_annotations, annotation) then
        table.insert(stats.total_annotations, annotation)
      end

      if type(entries) == "table" then
        stats.total_endpoints = stats.total_endpoints + #entries
      else
        stats.total_endpoints = stats.total_endpoints + 1
      end

      -- Try to detect framework from annotation
      local framework = "unknown"
      if annotation:find "GET" or annotation:find "POST" or annotation:find "PUT" then
        if path:find "%.ts$" or path:find "%.js$" then
          framework = "NestJS/Express"
        elseif path:find "%.java$" then
          framework = "Spring Boot"
        end
      end

      if not stats.frameworks[framework] then
        stats.frameworks[framework] = 0
      end
      stats.frameworks[framework] = stats.frameworks[framework] + 1
    end
  end

  return stats
end

M.show_cache_status = function()
  local cache = require "endpoint.services.cache"
  local state = require "endpoint.core.state"
  local cache_config = state.get_config()

  if not cache_config then
    local default_config = require "endpoint.core.config"
    cache_config = {
      cache_ttl = default_config.cache_ttl or 5000,
      cache_mode = default_config.cache_mode or "none",
    }
  end

  -- Get UI configuration
  local endpoint = require "endpoint.core"
  local config = endpoint.get_config()
  local window_config = config.ui and config.ui.cache_status_window
    or {
      width = 80,
      height = "auto",
      center_align = false,
    }

  -- Get cache file paths
  local project_root = fs.get_project_root()
  local project_name = vim.fn.fnamemodify(project_root, ":t")
  local cache_dir = vim.fn.stdpath "data" .. "/endpoint.nvim/" .. project_name
  local find_cache_file = cache_dir .. "/find_cache.lua"
  local metadata_file = cache_dir .. "/metadata.lua"

  -- Get statistics
  local stats = get_cache_statistics()

  -- Build status content
  local lines = {}

  -- ASCII Title
  vim.list_extend(lines, create_ascii_title())

  -- Project Info Section
  vim.list_extend(lines, create_section_header("Project Information", "📁"))
  table.insert(lines, "│ Project Name:     " .. project_name)
  table.insert(lines, "│ Project Root:     " .. project_root)
  table.insert(lines, "│ Cache Mode:       " .. (cache_config.cache_mode or "none") .. " mode")

  table.insert(lines, "│ Configuration:    Global setup() only")

  if cache_config.cache_mode == "persistent" then
    table.insert(lines, "│ Cache Directory:  " .. cache_dir)
  end
  vim.list_extend(lines, create_section_footer())

  -- Cache Statistics Section
  vim.list_extend(lines, create_section_header("Cache Statistics", "📈"))
  table.insert(lines, "│ Cached Files:     " .. stats.total_files)
  table.insert(lines, "│ Total Endpoints:  " .. stats.total_endpoints)
  table.insert(lines, "│ Annotations:      " .. table.concat(stats.total_annotations, ", "))

  if next(stats.frameworks) then
    table.insert(lines, "│")
    table.insert(lines, "│ Frameworks Detected:")
    for framework, count in pairs(stats.frameworks) do
      table.insert(lines, "│   • " .. framework .. ": " .. count .. " endpoints")
    end
  end
  vim.list_extend(lines, create_section_footer())

  -- File Cache Section (for persistent mode)
  if cache_config.cache_mode == "persistent" then
    vim.list_extend(lines, create_section_header("Persistent Cache Files", "💾"))

    local find_exists = vim.fn.filereadable(find_cache_file) == 1
    local meta_exists = vim.fn.filereadable(metadata_file) == 1

    table.insert(
      lines,
      "│ Find Cache:       " .. (find_exists and "✅ " .. format_file_size(find_cache_file) or "❌ Not found")
    )
    table.insert(
      lines,
      "│ Metadata:         " .. (meta_exists and "✅ " .. format_file_size(metadata_file) or "❌ Not found")
    )

    if meta_exists then
      local ok, metadata = pcall(dofile, metadata_file)
      if ok and metadata then
        table.insert(lines, "│")
        table.insert(lines, "│ Created:          " .. os.date("%Y-%m-%d %H:%M:%S", metadata.created_at or 0))
        table.insert(lines, "│ Version:          " .. (metadata.version or "unknown"))
      end
    end
    vim.list_extend(lines, create_section_footer())
  end

  -- Memory Usage Section with Tree Structure
  vim.list_extend(lines, create_section_header("Cache Tree View", "🌳"))
  local find_table = cache.get_find_table()

  -- Create line-to-location mapping for navigation
  local line_map = {}

  if next(find_table) then
    -- Group files by directory for tree structure
    local tree = {}
    for path, path_data in pairs(find_table) do
      local dir = vim.fn.fnamemodify(path, ":h")
      local filename = vim.fn.fnamemodify(path, ":t")

      if not tree[dir] then
        tree[dir] = {}
      end
      tree[dir][filename] = path_data
    end

    local sorted_dirs = {}
    for dir, _ in pairs(tree) do
      table.insert(sorted_dirs, dir)
    end
    table.sort(sorted_dirs)

    for i, dir in ipairs(sorted_dirs) do
      local dir_name = vim.fn.fnamemodify(dir, ":t")
      local is_last_dir = (i == #sorted_dirs)

      -- Directory node
      table.insert(lines, "│ " .. (is_last_dir and "└─" or "├─") .. " 📁 " .. dir_name .. "/")

      local files = {}
      for filename, _ in pairs(tree[dir]) do
        table.insert(files, filename)
      end
      table.sort(files)

      for j, filename in ipairs(files) do
        local is_last_file = (j == #files)
        local path_data = tree[dir][filename]
        local prefix = "│ " .. (is_last_dir and "    " or "│   ") .. (is_last_file and "└─" or "├─")

        -- File node with endpoint count
        local total_endpoints = 0
        for _, entries in pairs(path_data) do
          total_endpoints = total_endpoints + (type(entries) == "table" and #entries or 1)
        end

        local file_line = prefix
          .. " 📄 "
          .. filename
          .. " ("
          .. total_endpoints
          .. " endpoint"
          .. (total_endpoints > 1 and "s" or "")
          .. ")"
        table.insert(lines, file_line)

        -- Store file mapping for navigation
        local full_path = dir .. "/" .. filename
        line_map[#lines] = {
          type = "file",
          path = full_path,
          line_number = 1,
        }

        -- Annotation nodes
        local annotations = {}
        for annotation, _ in pairs(path_data) do
          table.insert(annotations, annotation)
        end
        table.sort(annotations)

        for k, annotation in ipairs(annotations) do
          local is_last_annotation = (k == #annotations)
          local entries = path_data[annotation]
          local count = type(entries) == "table" and #entries or 1
          local method_prefix = "│ "
            .. (is_last_dir and "    " or "│   ")
            .. (is_last_file and "    " or "│   ")
            .. (is_last_annotation and "└─" or "├─")

          -- Method/annotation with endpoint details
          table.insert(lines, method_prefix .. " 🔗 " .. annotation .. " (" .. count .. ")")

          -- Show individual endpoints if multiple
          if type(entries) == "table" and #entries > 1 then
            for l, entry in ipairs(entries) do
              local is_last_entry = (l == #entries)
              local entry_prefix = "│ "
                .. (is_last_dir and "    " or "│   ")
                .. (is_last_file and "    " or "│   ")
                .. (is_last_annotation and "    " or "│   ")
                .. (is_last_entry and "└─" or "├─")
              table.insert(lines, entry_prefix .. " ➤ " .. (entry.value or "unknown endpoint"))

              -- Store endpoint mapping for navigation
              local full_path = dir .. "/" .. filename
              line_map[#lines] = {
                type = "endpoint",
                path = full_path,
                line_number = entry.line_number or 1,
                column = entry.column or 1,
                value = entry.value,
                annotation = annotation,
              }
            end
          elseif type(entries) == "table" then
            local entry_prefix = "│ "
              .. (is_last_dir and "    " or "│   ")
              .. (is_last_file and "    " or "│   ")
              .. (is_last_annotation and "    " or "│   ")
              .. "└─"
            local value = entries.value or (entries[1] and entries[1].value) or "unknown endpoint"
            table.insert(lines, entry_prefix .. " ➤ " .. value)

            -- Store endpoint mapping for navigation
            local full_path = dir .. "/" .. filename
            local entry = entries[1] or entries
            line_map[#lines] = {
              type = "endpoint",
              path = full_path,
              line_number = entry.line_number or 1,
              column = entry.column or 1,
              value = value,
              annotation = annotation,
            }
          end
        end
      end
    end

    table.insert(lines, "│")
  else
    table.insert(lines, "│ └─ 🌵 No cached data found (cache is empty)")
    table.insert(lines, "│")
  end
  vim.list_extend(lines, create_section_footer())

  -- Actions Section
  vim.list_extend(lines, create_section_header("Available Actions", "⚡"))
  table.insert(lines, "│ <Enter> Navigate to file/endpoint under cursor")
  table.insert(lines, "│ <C-r>   Refresh cache status")
  table.insert(lines, "│ <C-c>   Clear all cache")
  table.insert(lines, "│ <C-s>   Save cache (persistent mode)")
  table.insert(lines, "│ q       Close this window")
  vim.list_extend(lines, create_section_footer())

  -- Find or create buffer
  local buf_name = "Endpoint Cache Status"
  local existing_buf = vim.fn.bufnr(buf_name)
  local buf

  if existing_buf ~= -1 then
    -- Reuse existing buffer
    buf = existing_buf
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
  else
    -- Create new buffer
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_name(buf, buf_name)
  end

  -- Calculate window dimensions based on configuration
  local width
  if window_config.width == "max" then
    width = vim.o.columns - 4
  else
    width = math.min(window_config.width or 80, vim.o.columns - 4)
  end

  local height
  if window_config.height == "auto" then
    height = math.min(#lines + 2, vim.o.lines - 4)
  elseif window_config.height == "max" then
    height = vim.o.lines - 4
  else
    height = math.min(window_config.height or (#lines + 2), vim.o.lines - 4)
  end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = "rounded",
    title = " 🚀 Cache Status ",
    title_pos = "center",
  })

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "filetype", "endpoint-cache-status")

  -- Key mappings
  local function map(key, func, desc)
    vim.api.nvim_buf_set_keymap(buf, "n", key, "", {
      noremap = true,
      silent = true,
      callback = func,
      desc = desc,
    })
  end

  map("<CR>", function()
    local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
    local location = line_map[cursor_line]

    if location then
      vim.api.nvim_win_close(win, true)

      -- Open the file
      if vim.fn.filereadable(location.path) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(location.path))

        -- Navigate to specific line and column if it's an endpoint
        if location.type == "endpoint" and location.line_number then
          vim.api.nvim_win_set_cursor(0, { location.line_number, (location.column or 1) - 1 })
          vim.cmd "normal! zz" -- Center the line

          -- Highlight the line briefly
          vim.cmd "normal! V"
          vim.defer_fn(function()
            if vim.api.nvim_get_mode().mode == "V" then
              vim.cmd "normal! <Esc>"
            end
          end, 1000)

          -- Show info about what was navigated to
          local info = string.format("📍 %s: %s", location.annotation or "Endpoint", location.value or "")
          vim.notify(info, vim.log.levels.INFO)
        else
          vim.notify("📁 Opened: " .. vim.fn.fnamemodify(location.path, ":t"), vim.log.levels.INFO)
        end
      else
        vim.notify("❌ File not found: " .. location.path, vim.log.levels.ERROR)
      end
    end
  end, "Navigate to file/endpoint under cursor")

  map("q", function()
    vim.api.nvim_win_close(win, true)
  end, "Close cache status window")

  map("<C-r>", function()
    vim.api.nvim_win_close(win, true)
    M.show_cache_status()
  end, "Refresh cache status")

  map("<C-c>", function()
    cache.clear_persistent_cache()
    vim.api.nvim_win_close(win, true)
    vim.notify("🗑️ Cache cleared successfully!", vim.log.levels.INFO)
  end, "Clear cache")

  map("<C-s>", function()
    if cache_config.cache_mode == "persistent" then
      cache.save_to_file()
      vim.notify("💾 Cache saved successfully!", vim.log.levels.INFO)
    else
      vim.notify("⚠️ Cache save only available in persistent mode", vim.log.levels.WARN)
    end
  end, "Save cache")

  -- Syntax highlighting
  vim.api.nvim_buf_call(buf, function()
    vim.cmd [[
      syntax match EndpointCacheTitle "╔.*╗\|║.*║\|╚.*╝"
      syntax match EndpointCacheBox "┌\|┐\|└\|┘\|│\|─\|├\|└─\|├─"
      syntax match EndpointCacheIcon "🚀\|📁\|📈\|💾\|🧠\|⚡\|📄\|✅\|❌\|•\|🌳\|🔗\|➤\|🌵"
      syntax match EndpointCacheSuccess "✅.*"
      syntax match EndpointCacheError "❌.*"
      syntax match EndpointCacheKey "\(Project Name\|Project Root\|Cache Mode\|Cache Directory\|Project Config\|Cached Files\|Total Endpoints\|Annotations\|Find Cache\|Metadata\|Created\|Version\):" containedin=ALL
      syntax match EndpointCacheTreeDir "📁 .*/"
      syntax match EndpointCacheTreeFile "📄 .*"
      syntax match EndpointCacheTreeMethod "🔗 .*"
      syntax match EndpointCacheTreeEndpoint "➤ .*"

      hi def link EndpointCacheTitle Special
      hi def link EndpointCacheBox Comment
      hi def link EndpointCacheIcon Identifier
      hi def link EndpointCacheSuccess String
      hi def link EndpointCacheError ErrorMsg
      hi def link EndpointCacheKey Keyword
      hi def link EndpointCacheTreeDir Directory
      hi def link EndpointCacheTreeFile Type
      hi def link EndpointCacheTreeMethod Function
      hi def link EndpointCacheTreeEndpoint String
    ]]
  end)

  return buf, win
end

return M
