---@meta

-- UI Configuration
---@class endpoint.ui.config
---@field method_colors table<string, string>
---@field method_icons table<string, string>
---@field show_icons boolean
---@field show_method boolean

-- Core Configuration
---@class endpoint.config
---@field cache_mode "none" | "session" | "persistent"
---@field picker "telescope" | "vim_ui_select" | "snacks"
---@field picker_opts table
---@field ui endpoint.ui.config

-- Endpoint Entry
---@class endpoint.entry
---@field file_path string
---@field line_number number
---@field column number
---@field method string
---@field endpoint_path string
---@field display_value string

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
