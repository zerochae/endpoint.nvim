---@meta

-- Method configuration (new structure)
---@class endpoint.ui.method
---@field icon string
---@field color string

-- UI Configuration (updated for new structure)
---@class endpoint.ui.config
---@field show_icons boolean
---@field show_method boolean
---@field methods? table<string, endpoint.ui.method> -- New structure
---@field method_colors? table<string, string> -- Legacy structure (deprecated)
---@field method_icons? table<string, string> -- Legacy structure (deprecated)

-- Cache configuration (new structure)
---@class endpoint.cache.config
---@field mode "none" | "session" | "persistent"

-- Picker configuration (new structure)
---@class endpoint.picker.config
---@field type "telescope" | "vim_ui_select" | "snacks"
---@field options table

-- Core Configuration (updated for new structure)
---@class endpoint.config
---@field cache? endpoint.cache.config -- New structure
---@field picker? endpoint.picker.config -- New structure  
---@field ui endpoint.ui.config
---@field frameworks? table
---@field cache_mode? "none" | "session" | "persistent" -- Legacy (deprecated)
---@field picker_opts? table -- Legacy (deprecated)

-- Endpoint Entry (standardized based on Spring framework)
---@class endpoint.entry
---@field method string HTTP method (e.g., "GET", "POST")
---@field endpoint_path string API endpoint path (e.g., "/api/users")
---@field file_path string Source file path
---@field line_number number Line number in source file
---@field column number Column number in source file
---@field display_value string Display text for UI (e.g., "GET /api/users")
---@field confidence? number Confidence score (0.0-1.0), defaults to 1.0
---@field tags? string[] Framework-specific tags (e.g., {"api", "spring"})
---@field framework? string Framework name

-- Cache Module (Function-based)
---@class endpoint.cache
---@field set_mode fun(mode: string)
---@field get_mode fun(): string
---@field is_valid fun(key: string): boolean
---@field save_endpoint fun(method: string, endpoint: endpoint.entry)
---@field save_preview fun(key: string, file_path: string, line_number: number, column: number)
---@field get_endpoints fun(method: string): endpoint.entry[]
---@field get_preview fun(key: string): endpoint.cache.preview?
---@field clear fun()
---@field save_to_file fun()
---@field load_from_file fun()
---@field get_stats fun(): endpoint.cache.stats

---@class endpoint.cache.preview
---@field path string
---@field line_number number
---@field column number

---@class endpoint.cache.stats
---@field find_entries number
---@field preview_entries number
---@field mode string
---@field timestamps string[]

-- Framework Module (Function-based)
---@class endpoint.framework
---@field detect fun(): boolean
---@field get_search_cmd fun(method: string): string
---@field parse_line fun(line: string, method: string): endpoint.entry?

-- Scanner Module (Function-based)
---@class endpoint.scanner
---@field scan fun(method: string): endpoint.entry[]
---@field detect_framework fun(): endpoint.framework?
---@field prepare_preview fun(endpoints: endpoint.entry[])

-- Picker Module (Function-based)
---@class endpoint.picker
---@field show fun(endpoints: endpoint.entry[], opts?: table)

-- Framework Implementations
---@class endpoint.frameworks.spring : endpoint.framework
---@class endpoint.frameworks.fastapi : endpoint.framework
---@class endpoint.frameworks.nestjs : endpoint.framework
---@class endpoint.frameworks.symfony : endpoint.framework
---@class endpoint.frameworks.rails : endpoint.framework

-- Picker Implementations
---@class endpoint.pickers.telescope : endpoint.picker
---@field is_available fun(): boolean
---@field show fun(endpoints: endpoint.entry[], opts?: table)
---@field create_endpoint_previewer fun(): table

---@class endpoint.pickers.vim_ui_select : endpoint.picker
---@field is_available fun(): boolean
---@field show fun(endpoints: endpoint.entry[], opts?: table)

---@class endpoint.pickers.snacks : endpoint.picker
---@field is_available fun(): boolean
---@field show fun(endpoints: endpoint.entry[], opts?: table)
