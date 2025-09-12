---@diagnostic disable: duplicate-doc-field
---@meta

-- UI Configuration
---@class endpoint.UIConfig
---@field method_colors table<string, string>
---@field method_icons table<string, string>
---@field show_icons boolean
---@field show_method boolean

-- Core Configuration
---@class endpoint.Config
---@field cache_mode "none" | "session" | "persistent"
---@field debug boolean
---@field picker "telescope" | "vim_ui_select" | "snacks"
---@field picker_opts table
---@field methods string[]
---@field rg_additional_args string
---@field ui endpoint.UIConfig

-- Endpoint Data
---@class endpoint.Endpoint
---@field file_path string
---@field line_number number
---@field column number
---@field method string
---@field endpoint_path string
---@field display_value string

-- Cache Module (Function-based)
---@class endpoint.Cache
---@field set_mode fun(mode: string)
---@field get_mode fun(): string
---@field is_valid fun(key: string): boolean
---@field save_endpoint fun(method: string, endpoint: endpoint.Endpoint)
---@field save_preview fun(key: string, file_path: string, line_number: number, column: number)
---@field get_endpoints fun(method: string): endpoint.Endpoint[]
---@field get_preview fun(key: string): endpoint.PreviewData?
---@field clear fun()
---@field save_to_file fun()
---@field load_from_file fun()
---@field get_stats fun(): endpoint.CacheStats

---@class endpoint.PreviewData
---@field path string
---@field line_number number
---@field column number

---@class endpoint.CacheStats
---@field find_entries number
---@field preview_entries number
---@field mode string
---@field timestamps string[]

-- Framework Module (Function-based)
---@class endpoint.Framework
---@field detect fun(): boolean
---@field get_search_cmd fun(method: string): string
---@field parse_line fun(line: string, method: string): endpoint.Endpoint?

-- Scanner Module (Function-based)
---@class endpoint.Scanner
---@field scan fun(method: string): endpoint.Endpoint[]
---@field detect_framework fun(): endpoint.Framework?
---@field prepare_preview fun(endpoints: endpoint.Endpoint[])

-- Picker Module (Function-based)
---@class endpoint.Picker
---@field show fun(endpoints: endpoint.Endpoint[], opts?: table)

-- Framework Implementations
---@class endpoint.SpringFramework : endpoint.Framework
---@class endpoint.FastAPIFramework : endpoint.Framework
---@class endpoint.NestJSFramework : endpoint.Framework
---@class endpoint.SymfonyFramework : endpoint.Framework
---@class endpoint.RailsFramework : endpoint.Framework

-- Picker Implementations
---@class endpoint.TelescopePicker : endpoint.Picker
---@class endpoint.VimUISelectPicker : endpoint.Picker
---@class endpoint.SnacksPicker : endpoint.Picker
