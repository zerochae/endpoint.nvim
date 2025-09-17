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

-- Cache Manager (OOP)
---@class CacheManager
---@field private cached_endpoints endpoint.entry[]
---@field private cache_timestamp number

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

-- Cache Module (Function-based)
---@class endpoint.cache
---@field set_mode fun(mode: string)
---@field get_mode fun(): string
---@field is_valid fun(): boolean
---@field save_endpoints fun(endpoints: endpoint.entry[])
---@field get_endpoints fun(): endpoint.entry[]
---@field clear fun()
---@field save_to_file fun()
---@field load_from_file fun()
---@field get_stats fun(): endpoint.cache.stats

---@class endpoint.cache.stats
---@field total_endpoints number
---@field valid boolean
---@field mode string
---@field last_updated? number

-- ========================================
-- NEW OOP FRAMEWORK ARCHITECTURE
-- ========================================

-- Framework base alias for compatibility
---@alias endpoint.framework_base Framework

-- Config type alias for UI configurations
---@alias endpoint.Config endpoint.config

-- Base Framework Class
---@class Framework
---@field protected name string Framework name
---@field protected config table Framework configuration
---@field protected detection_strategy DetectionStrategy
---@field protected parsing_strategy ParsingStrategy

-- Detection Strategy Pattern
---@class DetectionStrategy
---@field protected detection_name string

---@class DependencyBasedDetectionStrategy : DetectionStrategy
---@field private required_dependencies string[]
---@field private manifest_files string[]

-- Parsing Strategy Pattern
---@class ParsingStrategy
---@field protected parsing_strategy_name string

---@class AnnotationBasedParsingStrategy : ParsingStrategy
---@field private annotation_patterns table<string, string[]>
---@field private path_extraction_patterns string[]
---@field private method_mapping table<string, string>

-- Event Manager (Observer Pattern)
---@class EventManager
---@field private event_listeners table<string, function[]>

-- Endpoint Manager (Main Orchestrator)
---@class EndpointManager
---@field private registered_frameworks Framework[]
---@field private event_manager EventManager
---@field private cache_manager CacheManager
---@field private picker_manager PickerManager
---@field private _initialized boolean

-- Picker Manager (Factory Pattern)
---@class PickerManager
---@field private available_pickers table<string, table>

-- ========================================
-- CONCRETE FRAMEWORK IMPLEMENTATIONS
-- ========================================

---@class SpringFramework : Framework

---@class FastApiFramework : Framework

---@class ExpressFramework : Framework

---@class FlaskFramework : Framework

---@class RailsFramework : Framework

---@class NestJsFramework : Framework

---@class DjangoFramework : Framework

---@class GinFramework : Framework

---@class SymfonyFramework : Framework

---@class KtorFramework : Framework

---@class AxumFramework : Framework

---@class PhoenixFramework : Framework

---@class DotNetFramework : Framework

-- ========================================
-- PICKER IMPLEMENTATIONS
-- ========================================

-- Picker Module (Function-based)
---@class endpoint.picker
---@field show fun(endpoints: endpoint.entry[], opts?: table)

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
-- PICKER IMPLEMENTATIONS (OOP)
-- ========================================

-- Base Picker Class
---@class Picker
---@field protected name string

-- Concrete Picker Classes
---@class TelescopePicker : Picker
---@field private telescope_available boolean
---@field private highlight_ns integer

---@class SnacksPicker : Picker
---@field private snacks_available boolean

---@class VimUiSelectPicker : Picker

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
---@field detect_frameworks fun(): Framework[]
---@field scan_with_framework fun(framework_name: string, opts?: table): endpoint.entry[]
