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

-- Base Framework Class
---@class Framework
---@field protected name string Framework name
---@field protected config table Framework configuration
---@field protected detection_strategy DetectionStrategy
---@field protected parsing_strategy ParsingStrategy
---@field new fun(self: Framework, name: string, config?: table): Framework
---@field detect fun(self: Framework): boolean
---@field parse fun(self: Framework, content: string, file_path: string, line_number: number, column: number): endpoint.entry|nil
---@field scan fun(self: Framework, options?: table): endpoint.entry[]
---@field get_name fun(self: Framework): string
---@field get_config fun(self: Framework): table
---@field get_search_cmd fun(self: Framework): string

-- Detection Strategy Pattern
---@class DetectionStrategy
---@field protected strategy_name string
---@field new fun(self: DetectionStrategy, strategy_name: string): DetectionStrategy
---@field is_target_detected fun(self: DetectionStrategy): boolean
---@field get_strategy_name fun(self: DetectionStrategy): string
---@field get_detection_details fun(self: DetectionStrategy): table|nil

---@class DependencyBasedDetectionStrategy : DetectionStrategy
---@field private required_dependencies string[]
---@field private manifest_files string[]
---@field new fun(self: DependencyBasedDetectionStrategy, required_dependencies: string[], manifest_files: string[], strategy_name?: string): DependencyBasedDetectionStrategy

-- Parsing Strategy Pattern
---@class ParsingStrategy
---@field protected parsing_strategy_name string
---@field new fun(self: ParsingStrategy, parsing_strategy_name: string): ParsingStrategy
---@field parse_content fun(self: ParsingStrategy, content: string, file_path: string, line_number: number, column: number): endpoint.entry|nil
---@field get_strategy_name fun(self: ParsingStrategy): string
---@field is_content_valid_for_parsing fun(self: ParsingStrategy, content: string): boolean
---@field get_parsing_confidence fun(self: ParsingStrategy, content: string): number

---@class AnnotationBasedParsingStrategy : ParsingStrategy
---@field private annotation_patterns table<string, string[]>
---@field private path_extraction_patterns string[]
---@field private method_mapping table<string, string>
---@field new fun(self: AnnotationBasedParsingStrategy, annotation_patterns: table<string, string[]>, path_extraction_patterns: string[], method_mapping?: table<string, string>): AnnotationBasedParsingStrategy

-- Event Manager (Observer Pattern)
---@class EventManager
---@field private event_listeners table<string, function[]>
---@field new fun(self: EventManager): EventManager
---@field add_event_listener fun(self: EventManager, event_type: string, listener_callback: function, listener_priority?: number)
---@field remove_event_listener fun(self: EventManager, event_type: string, listener_callback: function): boolean
---@field emit_event fun(self: EventManager, event_type: string, event_data?: table): table
---@field get_registered_event_types fun(self: EventManager): string[]
---@field get_listener_count fun(self: EventManager, event_type: string): number

-- Endpoint Manager (Main Orchestrator)
---@class EndpointManager
---@field private registered_frameworks Framework[]
---@field private event_manager EventManager
---@field new fun(self: EndpointManager): EndpointManager
---@field register_framework fun(self: EndpointManager, framework_instance: Framework)
---@field unregister_framework fun(self: EndpointManager, framework_name: string): boolean
---@field get_registered_frameworks fun(self: EndpointManager): Framework[]
---@field detect_project_frameworks fun(self: EndpointManager): Framework[]
---@field scan_all_endpoints fun(self: EndpointManager, scan_options?: table): endpoint.entry[]
---@field scan_with_framework fun(self: EndpointManager, framework_name: string, scan_options?: table): endpoint.entry[]
---@field get_event_manager fun(self: EndpointManager): EventManager
---@field add_event_listener fun(self: EndpointManager, event_type: string, listener_callback: function, listener_priority?: number)
---@field remove_event_listener fun(self: EndpointManager, event_type: string, listener_callback: function): boolean
---@field get_framework_info fun(self: EndpointManager): table[]

-- Framework Registry (Factory Pattern)
---@class FrameworkRegistry
---@field private endpoint_manager EndpointManager
---@field new fun(self: FrameworkRegistry): FrameworkRegistry
---@field register_all_frameworks fun(self: FrameworkRegistry)
---@field get_endpoint_manager fun(self: FrameworkRegistry): EndpointManager
---@field scan_all_endpoints fun(self: FrameworkRegistry, scan_options?: table): endpoint.entry[]
---@field scan_with_framework fun(self: FrameworkRegistry, framework_name: string, scan_options?: table): endpoint.entry[]
---@field get_framework_info fun(self: FrameworkRegistry): table[]
---@field detect_project_frameworks fun(self: FrameworkRegistry): Framework[]

-- ========================================
-- CONCRETE FRAMEWORK IMPLEMENTATIONS
-- ========================================

---@class SpringFramework : Framework
---@field new fun(self: SpringFramework): SpringFramework

---@class FastApiFramework : Framework
---@field new fun(self: FastApiFramework): FastApiFramework

---@class ExpressFramework : Framework
---@field new fun(self: ExpressFramework): ExpressFramework

---@class FlaskFramework : Framework
---@field new fun(self: FlaskFramework): FlaskFramework

---@class RailsFramework : Framework
---@field new fun(self: RailsFramework): RailsFramework

---@class NestJsFramework : Framework
---@field new fun(self: NestJsFramework): NestJsFramework

---@class DjangoFramework : Framework
---@field new fun(self: DjangoFramework): DjangoFramework

---@class GinFramework : Framework
---@field new fun(self: GinFramework): GinFramework

---@class SymfonyFramework : Framework
---@field new fun(self: SymfonyFramework): SymfonyFramework

---@class KtorFramework : Framework
---@field new fun(self: KtorFramework): KtorFramework

---@class AxumFramework : Framework
---@field new fun(self: AxumFramework): AxumFramework

---@class PhoenixFramework : Framework
---@field new fun(self: PhoenixFramework): PhoenixFramework

---@class DotNetFramework : Framework
---@field new fun(self: DotNetFramework): DotNetFramework

-- ========================================
-- PICKER IMPLEMENTATIONS
-- ========================================

-- Picker Module (Function-based)
---@class endpoint.picker
---@field show fun(endpoints: endpoint.entry[], opts?: table)

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
-- MAIN MODULE INTERFACE
-- ========================================

-- Main Module Interface (updated for new OOP structure)
---@class endpoint
---@field setup fun(user_config?: table)
---@field find fun(opts?: table)
---@field find_endpoints fun(opts?: table) -- Alias for find
---@field clear_cache fun()
---@field show_cache_stats fun()
---@field refresh fun()
---@field get_config fun(): table
---@field get_framework_registry fun(): FrameworkRegistry|nil
---@field get_endpoint_manager fun(): EndpointManager|nil
---@field get_framework_info fun(): table[]
---@field detect_frameworks fun(): Framework[]
---@field scan_with_framework fun(framework_name: string, opts?: table): endpoint.entry[]