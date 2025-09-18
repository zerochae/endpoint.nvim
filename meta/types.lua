---@meta

-- ========================================
-- CORE TYPES
-- ========================================

-- Endpoint Entry (standardized based on OOP framework structure)
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
---@field metadata? table Additional framework-specific metadata
---@field action? string Rails controller action name
---@field controller? string Rails controller name
---@field component_file_path? string React Router component file path
---@field component_name? string React Router component name

-- ========================================
-- CONFIGURATION TYPES
-- ========================================

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

-- Config type alias for UI configurations
---@alias endpoint.Config endpoint.config

-- Compatibility aliases for backward compatibility
---@alias EventManager endpoint.EventManager
---@alias PickerManager endpoint.PickerManager
---@alias CacheManager endpoint.CacheManager

-- ========================================
-- BASE CLASSES (OOP ARCHITECTURE)
-- ========================================

-- Base Framework Class
---@class Framework : endpoint.Framework
---@class endpoint.Framework
---@field protected name string Framework name
---@field protected config table Framework configuration
---@field protected detector endpoint.Detector
---@field protected parser endpoint.Parser
---@field new fun(self: endpoint.Framework, name: string, config?: table): endpoint.Framework
---@field _validate_config fun(self: endpoint.Framework)
---@field _initialize fun(self: endpoint.Framework)
---@field detect fun(self: endpoint.Framework): boolean
---@field parse fun(self: endpoint.Framework, content: string, file_path: string, line_number: number, column: number): endpoint.entry|nil
---@field get_search_cmd fun(self: endpoint.Framework): string
---@field scan fun(self: endpoint.Framework, options?: table): endpoint.entry[]
---@field _search_and_parse fun(self: endpoint.Framework, scan_options?: table): endpoint.entry[]
---@field _parse_result_line fun(self: endpoint.Framework, result_line: string): endpoint.entry[]
---@field _post_process_endpoints fun(self: endpoint.Framework, endpoints: endpoint.entry[]): endpoint.entry[]
---@field get_name fun(self: endpoint.Framework): string
---@field get_config fun(self: endpoint.Framework): table
---@field is_instance_of fun(self: endpoint.Framework, framework_class: table): boolean

-- Framework base alias for compatibility
---@alias endpoint.framework_base endpoint.Framework

-- Base Picker Class
---@class Picker : endpoint.Picker
---@class endpoint.Picker
---@field protected name string
---@field new fun(self: endpoint.Picker, name?: string): endpoint.Picker
---@field is_available fun(self: endpoint.Picker): boolean
---@field show fun(self: endpoint.Picker, endpoints?: endpoint.entry[], opts?: table)
---@field get_name fun(self: endpoint.Picker): string
---@field _validate_endpoints fun(self: endpoint.Picker, endpoints: endpoint.entry[]): boolean
---@field _format_endpoint_display fun(self: endpoint.Picker, endpoint: endpoint.entry): string
---@field _navigate_to_endpoint fun(self: endpoint.Picker, endpoint: endpoint.entry)

-- ========================================
-- CORE PATTERNS
-- ========================================

-- Detection Pattern
---@class endpoint.Detector
---@field protected detection_name string
---@field new fun(self: endpoint.Detector, detection_name: string, fields: table?): endpoint.Detector
---@field is_target_detected fun(self: endpoint.Detector): boolean
---@field get_name fun(self: endpoint.Detector): string
---@field get_detection_details fun(self: endpoint.Detector): table|nil

---@class endpoint.DependencyDetector : endpoint.Detector
---@field private required_dependencies string[]
---@field private manifest_files string[]
---@field private file_system_utils table
---@field new fun(self: endpoint.DependencyDetector, required_dependencies: string[], manifest_files: string[], name?: string): endpoint.DependencyDetector
---@field _check_manifest_file_for_dependencies fun(self: endpoint.DependencyDetector, manifest_file_path: string): boolean
---@field add_required_dependencies fun(self: endpoint.DependencyDetector, additional_dependencies: string[])
---@field add_manifest_files fun(self: endpoint.DependencyDetector, additional_manifest_files: string[])
---@field get_required_dependencies fun(self: endpoint.DependencyDetector): string[]
---@field get_manifest_files fun(self: endpoint.DependencyDetector): string[]

---@class endpoint.FileDetector : endpoint.Detector
---@field private required_indicator_files string[]
---@field private file_system_utils table

-- Parsing Pattern
---@class endpoint.Parser
---@field protected parser_name? string
---@field protected framework_name? string
---@field protected language? string
---@field new fun(self: endpoint.Parser, fields?: table): endpoint.Parser
---@field extract_base_path fun(self: endpoint.Parser, file_path: string, line_number: number): string
---@field extract_endpoint_path fun(self: endpoint.Parser, content: string): string|nil
---@field extract_method fun(self: endpoint.Parser, content: string): string|nil
---@field combine_paths fun(self: endpoint.Parser, base_path?: string, endpoint_path?: string): string
---@field parse_content fun(self: endpoint.Parser, content?: string, file_path?: string, line_number?: number, column?: number): endpoint.entry|nil
---@field parse_line_to_endpoints fun(self: endpoint.Parser, content?: string, file_path?: string, line_number?: number, column?: number): endpoint.entry[]
---@field get_name fun(self: endpoint.Parser): string
---@field is_content_valid_for_parsing fun(self: endpoint.Parser, content_to_validate?: string): boolean
---@field get_parsing_confidence fun(self: endpoint.Parser, content_to_analyze?: string): number
---@field create_metadata fun(self: endpoint.Parser, route_type: string, extra_metadata?: table, content?: string): table


---@class endpoint.RailsParser : endpoint.Parser
---
---@class endpoint.SpringParser : endpoint.Parser

-- ========================================
-- MANAGER CLASSES
-- ========================================

-- Cache Manager (OOP)
---@class endpoint.CacheManager
---@field private cached_endpoints endpoint.entry[]
---@field private cache_timestamp number
---@field new fun(self: endpoint.CacheManager): endpoint.CacheManager
---@field is_valid fun(self: endpoint.CacheManager): boolean
---@field get_endpoints fun(self: endpoint.CacheManager): endpoint.entry[]
---@field save_endpoints fun(self: endpoint.CacheManager, endpoints: endpoint.entry[])
---@field clear fun(self: endpoint.CacheManager)
---@field get_stats fun(self: endpoint.CacheManager): table

-- Event Manager (Observer Pattern)
---@class endpoint.EventManager
---@field private event_listeners table<string, endpoint.EventListener[]>
---@field new fun(self: endpoint.EventManager): endpoint.EventManager
---@field add_event_listener fun(self: endpoint.EventManager, event_type: string, listener_callback: function, listener_priority?: number)
---@field emit_event fun(self: endpoint.EventManager, event_type: string, event_data?: any): table[]
---@field remove_event_listener fun(self: endpoint.EventManager, event_type: string, listener_callback: function): boolean
---@field get_registered_event_types fun(self: endpoint.EventManager): string[]
---@field get_listener_count fun(self: endpoint.EventManager, event_type: string): number
---@field clear_event_listeners fun(self: endpoint.EventManager, event_type: string): number
---@field clear_all_event_listeners fun(self: endpoint.EventManager): number

---@class endpoint.EventListener
---@field callback_function function
---@field execution_priority number
---@field registration_timestamp number

-- Picker Manager (Factory Pattern)
---@class endpoint.PickerManager
---@field private available_pickers table<string, table>
---@field new fun(self: endpoint.PickerManager): endpoint.PickerManager
---@field _register_default_pickers fun(self: endpoint.PickerManager)
---@field get_picker fun(self: endpoint.PickerManager, picker_name: string): endpoint.Picker|nil
---@field get_all_pickers fun(self: endpoint.PickerManager): table<string, endpoint.Picker>
---@field register_picker fun(self: endpoint.PickerManager, picker_name: string, picker_instance: endpoint.Picker)
---@field is_picker_available fun(self: endpoint.PickerManager, picker_name: string): boolean
---@field get_best_available_picker fun(self: endpoint.PickerManager, preferred_picker_name?: string, fallback_picker_name?: string): endpoint.Picker, string

-- Endpoint Manager (Main Orchestrator)
---@class endpoint.EndpointManager
---@field private registered_frameworks endpoint.Framework[]
---@field private event_manager endpoint.EventManager
---@field private cache_manager endpoint.CacheManager
---@field private picker_manager endpoint.PickerManager
---@field private _initialized boolean

-- ========================================
-- CONCRETE FRAMEWORK IMPLEMENTATIONS
-- ========================================

---@class endpoint.SpringFramework : endpoint.Framework

---@class endpoint.RailsFramework : endpoint.Framework

---@class endpoint.FastApiFramework : endpoint.Framework

---@class endpoint.ExpressFramework : endpoint.Framework

---@class endpoint.FlaskFramework : endpoint.Framework

---@class endpoint.NestJsFramework : endpoint.Framework

---@class endpoint.DjangoFramework : endpoint.Framework

---@class endpoint.GinFramework : endpoint.Framework

---@class endpoint.SymfonyFramework : endpoint.Framework

---@class endpoint.KtorFramework : endpoint.Framework

---@class endpoint.AxumFramework : endpoint.Framework

---@class endpoint.PhoenixFramework : endpoint.Framework

---@class endpoint.DotNetFramework : endpoint.Framework

-- ========================================
-- CONCRETE PICKER IMPLEMENTATIONS
-- ========================================

---@class endpoint.TelescopePicker : endpoint.Picker
---@field private telescope_available boolean
---@field private highlight_ns integer

---@class endpoint.SnacksPicker : endpoint.Picker
---@field private snacks_available boolean

---@class endpoint.VimUiSelectPicker : endpoint.Picker

-- ========================================
-- UTILITY MODULES
-- ========================================

-- File System Utilities
---@class endpoint.utils.fs
---@field file_exists fun(target_file_path: string): boolean
---@field get_project_root fun(): string
---@field read_file fun(target_file_path: string): string[]|nil
---@field has_file fun(files: string|string[]): boolean
---@field file_contains fun(file_path: string, patterns: string|string[]): boolean
---@field get_cache_dir fun(project_root?: string): string

-- Ripgrep Utilities
---@class endpoint.utils.rg
---@field create_command fun(ripgrep_search_options: table): string
---@field common_exclude_patterns table
---@field common_file_patterns table

-- Logging Utilities
---@class endpoint.utils.log
---@field info fun(message: string, level?: number)
---@field framework_debug fun(message: string)
---@field endpoint fun(message: string, level?: number)

-- ========================================
-- LEGACY FUNCTION-BASED MODULES
-- ========================================

-- Picker Module (Function-based)
---@class endpoint.picker
---@field show fun(endpoints: endpoint.entry[], opts?: table)

-- ========================================
-- MAIN MODULE INTERFACE
-- ========================================

-- Main Module Interface (updated for new simplified OOP structure)
---@class endpoint
---@field setup fun(user_config?: table)
---@field find fun(opts?: table)
---@field clear_cache fun()
---@field show_cache_stats fun()
---@field refresh fun()
---@field get_config fun(): table
---@field get_framework_info fun(): table[]
---@field detect_frameworks fun(): endpoint.Framework[]
---@field scan_with_framework fun(framework_name: string, opts?: table): endpoint.entry[]
