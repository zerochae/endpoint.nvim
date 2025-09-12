---@meta

-- Core Types
---@class endpoint.Config
---@field cache_mode "none" | "session" | "persistent"
---@field debug boolean
---@field framework string
---@field methods string[]
---@field rg_additional_args string
---@field frameworks table<string, endpoint.FrameworkConfig>
---@field picker string
---@field picker_opts table
---@field ui endpoint.UIConfig
---@field framework_paths table<string, string>

---@class endpoint.UIConfig
---@field method_colors table<string, string>
---@field method_icons table<string, string>
---@field show_icons boolean
---@field show_method boolean

---@class endpoint.FrameworkConfig
---@field file_patterns string[]
---@field exclude_patterns string[]
---@field detection_files string[]
---@field patterns table<string, string[]>

-- Endpoint Types
---@class endpoint.Endpoint
---@field file_path string
---@field method string
---@field endpoint_path string  
---@field line_number number
---@field column number
---@field display_value string

---@class endpoint.ParsedLine
---@field file_path string
---@field line_number number
---@field column number
---@field endpoint_path string
---@field method string
---@field raw_line string
---@field content string

-- Manager Types
---@class endpoint.Manager
---@field module_name string
---@field registry table<string, string>
---@field instances table<string, any>
---@field default_type string
---@field register fun(type: string, module_path: string)
---@field get fun(type?: string): any
---@field get_available_types fun(): string[]
---@field clear_cache fun()
---@field has_type fun(type: string): boolean
---@field set_registry fun(config: table<string, string>)
---@field is_registry_empty fun(): boolean

-- Framework Registry Interface
---@class endpoint.FrameworkRegistry
---@field name string
---@field get_patterns fun(self: endpoint.FrameworkRegistry, method: string): string[]
---@field get_file_patterns fun(self: endpoint.FrameworkRegistry): string[]
---@field get_exclude_patterns fun(self: endpoint.FrameworkRegistry): string[]
---@field extract_endpoint_path fun(self: endpoint.FrameworkRegistry, content: string, method: string): string
---@field get_base_path fun(self: endpoint.FrameworkRegistry, file_path: string, line_number: number): string
---@field get_grep_cmd fun(self: endpoint.FrameworkRegistry, method: string, config: endpoint.Config): string
---@field parse_line fun(self: endpoint.FrameworkRegistry, line: string, method: string): endpoint.ParsedLine|nil
---@field can_handle fun(self: endpoint.FrameworkRegistry, line: string): boolean
---@field combine_paths fun(self: endpoint.FrameworkRegistry, base: string, endpoint: string): string

-- Picker Registry Interface  
---@class endpoint.PickerRegistry
---@field name string
---@field is_available fun(self: endpoint.PickerRegistry): boolean
---@field create_picker fun(self: endpoint.PickerRegistry, opts: endpoint.PickerOptions): boolean
---@field get_default_config fun(self: endpoint.PickerRegistry): table
---@field validate_options fun(self: endpoint.PickerRegistry, opts: table): boolean

---@class endpoint.PickerOptions
---@field prompt_title string
---@field preview_title string
---@field items endpoint.Endpoint[]
---@field on_select fun(item: endpoint.Endpoint)
---@field format_item fun(item: endpoint.Endpoint): string
---@field preview_item fun(item: endpoint.Endpoint): string
---@field picker_opts table

-- Cache Registry Interface
---@class endpoint.CacheRegistry
---@field name string
---@field is_cache_valid fun(self: endpoint.CacheRegistry, method: string): boolean
---@field should_use_cache fun(self: endpoint.CacheRegistry, method: string): boolean
---@field clear_for_realtime_mode fun(self: endpoint.CacheRegistry)
---@field save_to_file fun(self: endpoint.CacheRegistry)
---@field load_from_file fun(self: endpoint.CacheRegistry)

-- Scanner Registry Interface
---@class endpoint.ScannerRegistry  
---@field name string
---@field process fun(self: endpoint.ScannerRegistry, method: string): endpoint.Endpoint[]

-- Detector Registry Interface
---@class endpoint.DetectorRegistry
---@field name string
---@field detect fun(self: endpoint.DetectorRegistry, ...): any
---@field can_detect fun(self: endpoint.DetectorRegistry, ...): boolean
---@field get_priority fun(self: endpoint.DetectorRegistry): number
---@field get_description fun(self: endpoint.DetectorRegistry): string

-- Base Class Types
---@class endpoint.Base
---@field name string
---@field new fun(implementation: table, name?: string): table
---@field get_name fun(self: endpoint.Base): string
---@field validate fun(self: endpoint.Base): boolean
---@field get_type fun(self: endpoint.Base): string
---@field error fun(self: endpoint.Base, message: string)
---@field log fun(self: endpoint.Base, message: string, level?: number)

-- Cache Base extends endpoint.Base  
---@class endpoint.CacheBase : endpoint.Base
---@field new fun(implementation: table, name: string): table
---@field get_cache_config fun(self: endpoint.CacheBase): table
---@field cleanup_cache_by_size fun(self: endpoint.CacheBase, cache_table: table, max_entries: number, name: string)
---@field track_access fun(self: endpoint.CacheBase, cache_name: string, key: string)
---@field get_project_cache_dir fun(self: endpoint.CacheBase): string
---@field get_cache_files fun(self: endpoint.CacheBase): table
---@field ensure_cache_dir fun(self: endpoint.CacheBase)
---@field migrate_framework_keys fun(self: endpoint.CacheBase, timestamp_data: table?): table
---@field get_find_table fun(self: endpoint.CacheBase): table
---@field get_preview_table fun(self: endpoint.CacheBase): table
---@field get_cache_timestamp fun(self: endpoint.CacheBase): table
---@field set_cache_timestamp fun(self: endpoint.CacheBase, data: table?)
---@field clear_tables fun(self: endpoint.CacheBase)
---@field create_find_table_entry fun(self: endpoint.CacheBase, path: string, annotation: string)
---@field insert_to_find_table fun(self: endpoint.CacheBase, opts: table)
---@field insert_to_find_request_table fun(self: endpoint.CacheBase, opts: table)
---@field create_preview_entry fun(self: endpoint.CacheBase, endpoint: string, path: string, line_number: number, column: number)
---@field update_cache_timestamp fun(self: endpoint.CacheBase, annotation: string)
---@field get_cache_stats fun(self: endpoint.CacheBase): table

-- Framework Base extends endpoint.Base
---@class endpoint.FrameworkBase : endpoint.Base
---@field get_grep_cmd fun(self: endpoint.FrameworkBase, method: string, config: endpoint.Config): string
---@field parse_line fun(self: endpoint.FrameworkBase, line: string, method: string): endpoint.ParsedLine?
---@field combine_paths fun(self: endpoint.FrameworkBase, base: string, endpoint: string): string

-- Service Function Types
---@alias ShowPickerFunction fun(method: string, opts?: table): boolean
---@alias ScanFunction fun(method: string): endpoint.Endpoint[]
---@alias GetCurrentFrameworkFunction fun(): endpoint.FrameworkRegistry|nil, string|nil, endpoint.FrameworkConfig|nil

return {}
