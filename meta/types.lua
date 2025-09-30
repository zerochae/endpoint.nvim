---@meta

-- ========================================
-- LIBRARY TYPES
-- ========================================

-- Middleclass OOP Library (kikito/middleclass)
-- Base class for all OOP classes in endpoint.nvim
---@class Class
---@field name string Class name
---@field super Class|nil Parent class reference
---@field static table Static class members
---@field subclasses table<Class, boolean> Set of subclasses
---@field new fun(self: Class, ...): any Creates and initializes a new instance
---@field initialize fun(self: any, ...) Constructor method (override in subclasses)
---@field isInstanceOf fun(self: any, aClass: Class): boolean Checks if instance is of specific type
---@field subclass fun(self: Class, name: string): Class Creates a subclass
---@field isSubclassOf fun(self: Class, aClass: Class): boolean Checks if class is subclass of another
---@field include fun(self: Class, ...: table) Adds mixin methods to class
---@field allocate fun(self: Class): any Allocates instance without initialization
---@field __tostring fun(self: Class): string String representation
---@field __call fun(self: Class, ...: any): any Allows Class(...) syntax for new()

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
---@field end_line_number? number End line number in source file
---@field end_column? number End column number in source file
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
---@field options endpoint.picker.options

-- Picker options configuration
---@class endpoint.picker.options
---@field telescope? table Options passed to Telescope picker
---@field vim_ui_select? endpoint.picker.vim_ui_select.options Options for vim.ui.select picker
---@field snacks? table Options passed to Snacks.nvim picker

-- Vim UI Select picker options
---@class endpoint.picker.vim_ui_select.options
---@field filter_threshold? number Threshold for showing filter prompt (default: 20)
---@field filter_prompt? string Custom filter prompt text
---@field show_filter_examples? boolean Show filter examples in prompt (default: true)
---@field enable_filter? boolean Enable filtering for large lists (default: false)

-- Previewer configuration (new structure)
---@class endpoint.picker.previewer.config
---@field enable_highlighting boolean

-- Controller Name Extractor Configuration
---@class endpoint.controller_extractor
---@field pattern string Lua pattern to match file paths
---@field transform? fun(match: string): string Optional function to transform the matched name

-- Core Configuration (updated for new structure)
---@class endpoint.config
---@field cache? endpoint.cache.config -- New structure
---@field picker? endpoint.picker.config -- New structure
---@field previewer? endpoint.picker.previewer.config -- New structure
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
---@class endpoint.Framework : Class
---@field super Class Parent class reference
---@field name string Framework name
---@field config table Framework configuration
---@field detector endpoint.Detector
---@field parser endpoint.Parser
---@field controller_extractors? endpoint.controller_extractor[] Extractors for controller names from file paths
---@field initialize fun(self: endpoint.Framework, fields?: table)
---@field _validate_config fun(self: endpoint.Framework)
---@field _initialize fun(self: endpoint.Framework)
---@field detect fun(self: endpoint.Framework): boolean
---@field parse fun(self: endpoint.Framework, content: string, file_path: string, line_number: number, column: number): endpoint.entry|nil
---@field get_search_cmd fun(self: endpoint.Framework, method?: string): string
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
---@class endpoint.Picker : Class
---@field super Class Parent class reference
---@field name string
---@field themes? table
---@field initialize fun(self: endpoint.Picker, fields?: table)
---@field is_available fun(self: endpoint.Picker): boolean
---@field show fun(self: endpoint.Picker, endpoints?: endpoint.entry[], opts?: table)
---@field get_name fun(self: endpoint.Picker): string
---@field _validate_endpoints fun(self: endpoint.Picker, endpoints: endpoint.entry[]): boolean
---@field _format_endpoint_display fun(self: endpoint.Picker, endpoint: endpoint.entry): string
---@field _format_endpoint_with_theme fun(self: endpoint.Picker, endpoint: endpoint.entry, config: table): string
---@field _navigate_to_endpoint fun(self: endpoint.Picker, endpoint: endpoint.entry)

-- ========================================
-- CORE PATTERNS
-- ========================================

-- Detection Pattern
---@class endpoint.Detector : Class
---@field detection_name string
---@field required_dependencies string[]
---@field manifest_files string[]
---@field initialize fun(self: endpoint.Detector, required_dependencies: string[], manifest_files: string[], detection_name?: string)
---@field is_target_detected fun(self: endpoint.Detector): boolean
---@field get_name fun(self: endpoint.Detector): string
---@field get_detection_details fun(self: endpoint.Detector): table|nil
---@field _check_manifest_file_for_dependencies fun(self: endpoint.Detector, manifest_file_path: string): boolean
---@field add_required_dependencies fun(self: endpoint.Detector, additional_dependencies: string[])
---@field add_manifest_files fun(self: endpoint.Detector, additional_manifest_files: string[])
---@field get_required_dependencies fun(self: endpoint.Detector): string[]
---@field get_manifest_files fun(self: endpoint.Detector): string[]
---@field _should_check_submodules fun(self: endpoint.Detector): boolean
---@field _find_submodule_manifest_files fun(self: endpoint.Detector): string[]

-- Parsing Pattern
---@class endpoint.Parser : Class
---@field super Class Parent class reference
---@field parser_name? string
---@field framework_name? string
---@field language? string
---@field initialize fun(self: endpoint.Parser, fields?: table)
---@field extract_base_path fun(self: endpoint.Parser, file_path: string, line_number: number): string
---@field extract_endpoint_path fun(self: endpoint.Parser, content: string, file_path?: string, line_number?: number): string|nil
---@field extract_method fun(self: endpoint.Parser, content: string): string|nil
---@field combine_paths fun(self: endpoint.Parser, base_path?: string, endpoint_path?: string): string
---@field parse_content fun(self: endpoint.Parser, content?: string, file_path?: string, line_number?: number, column?: number): endpoint.entry|nil
---@field get_name fun(self: endpoint.Parser): string
---@field is_content_valid_for_parsing fun(self: endpoint.Parser, content_to_validate?: string): boolean
---@field get_parsing_confidence fun(self: endpoint.Parser, content_to_analyze?: string): number
---@field create_metadata fun(self: endpoint.Parser, route_type: string, extra_metadata?: table, content?: string): table

---@class endpoint.RailsParser : endpoint.Parser
---@field _extract_http_method fun(self: endpoint.RailsParser, content: string): string|nil
---@field _is_valid_route_line fun(self: endpoint.RailsParser, content: string): boolean
---@field _is_private_helper_method fun(self: endpoint.RailsParser, action_name: string): boolean
---@field _process_controller_action fun(self: endpoint.RailsParser, content: string, file_path: string, line_number: number, column: number): endpoint.entry|nil
---@field _process_resources_route fun(self: endpoint.RailsParser, content: string, file_path: string, line_number: number, column: number): endpoint.entry[]|nil
---@field _process_nested_routes fun(self: endpoint.RailsParser, content: string, file_path: string, line_number: number, column: number): endpoint.entry[]|nil
---@field _find_namespace_prefix fun(self: endpoint.RailsParser, file_path: string, line_number: number): string
---@field _find_parent_resource fun(self: endpoint.RailsParser, file_path: string, line_number: number): string|nil
---@field _find_controller_action fun(self: endpoint.RailsParser, resource_name: string, action_name: string): table|nil
---@field _is_private_method fun(self: endpoint.RailsParser, file_path: string, line_number: number): boolean
---@field _is_rails_content fun(self: endpoint.RailsParser, content: string): boolean

---@class endpoint.SpringParser : endpoint.Parser
---@field _read_file_lines fun(self: endpoint.SpringParser, file_path: string, line_number: number): string[]|nil
---@field _find_class_level_request_mapping fun(self: endpoint.SpringParser, lines: string[], line_number: number): string
---@field _extract_request_mapping_path fun(self: endpoint.SpringParser, annotation_line: string): string|nil
---@field _is_class_level_request_mapping fun(self: endpoint.SpringParser, content: string): boolean
---@field _extract_path_from_specific_mapping fun(self: endpoint.SpringParser, content: string): string|nil
---@field _extract_path_from_request_mapping_with_method fun(self: endpoint.SpringParser, content: string): string|nil
---@field _is_root_path_mapping fun(self: endpoint.SpringParser, content: string): boolean
---@field _extract_method_from_specific_mapping fun(self: endpoint.SpringParser, content: string): string|nil
---@field _extract_method_from_request_mapping fun(self: endpoint.SpringParser, content: string): string|nil
---@field _extract_methods_from_request_mapping fun(self: endpoint.SpringParser, content: string): string[]
---@field _looks_like_incomplete_spring_annotation fun(self: endpoint.SpringParser, content: string): boolean
---@field _get_extended_annotation_content fun(self: endpoint.SpringParser, file_path: string, start_line: number): string|nil, number|nil, number|nil

---@class endpoint.Highlighter : Class
---@field highlight_ns number
---@field is_highlighting_enabled fun(self: endpoint.Highlighter, config: table): boolean
---@field clear_highlights fun(self: endpoint.Highlighter, bufnr: number)
---@field highlight_line_range fun(self: endpoint.Highlighter, bufnr: number, start_line: number, start_col: number, end_line?: number, highlight_group?: string)
---@field highlight_endpoint fun(self: endpoint.Highlighter, bufnr: number, endpoint: table, highlight_group?: string)
---@field highlight_component_definition fun(self: endpoint.Highlighter, bufnr: number, endpoint: table, highlight_group?: string)
---@field calculate_highlight_length fun(self: endpoint.Highlighter, entry: table, method_icon: string, method_text: string): number

---@class endpoint.Themes : Class
---@field DEFAULT_METHOD_COLORS table<string, string>
---@field DEFAULT_METHOD_ICONS table<string, string>
---@field get_method_color fun(self: endpoint.Themes, method: string, config: table): string
---@field get_method_icon fun(self: endpoint.Themes, method: string, config: table): string
---@field get_method_text fun(self: endpoint.Themes, method: string, config: table): string

---@class endpoint.SymfonyParser : endpoint.Parser
---@field _last_end_line_number number|nil
---@field _read_file_lines fun(self: endpoint.SymfonyParser, file_path: string, line_number: number): string[]|nil
---@field _find_controller_level_route fun(self: endpoint.SymfonyParser, lines: string[], line_number: number): string
---@field _extract_controller_route_path fun(self: endpoint.SymfonyParser, annotation_line: string): string|nil
---@field _is_controller_level_route fun(self: endpoint.SymfonyParser, content: string): boolean
---@field _extract_path_from_php8_attributes fun(self: endpoint.SymfonyParser, content: string): string|nil
---@field _extract_path_from_annotations fun(self: endpoint.SymfonyParser, content: string): string|nil
---@field _extract_path_from_docblock fun(self: endpoint.SymfonyParser, content: string): string|nil
---@field _extract_path_single_line fun(self: endpoint.SymfonyParser, content: string): string|nil
---@field _extract_path_multiline fun(self: endpoint.SymfonyParser, file_path: string, start_line: number, content: string): string|nil, number|nil
---@field _is_multiline_annotation fun(self: endpoint.SymfonyParser, content: string): boolean
---@field _extract_methods_multiline fun(self: endpoint.SymfonyParser, content: string, file_path: string, line_number: number): string[]
---@field _extract_methods_from_annotation fun(self: endpoint.SymfonyParser, content: string): string[]
---@field _combine_paths fun(self: endpoint.SymfonyParser, base?: string, endpoint?: string): string
---@field _detect_annotation_type fun(self: endpoint.SymfonyParser, content: string): string
---@field _calculate_annotation_column fun(self: endpoint.SymfonyParser, content: string, file_path: string, line_number: number, ripgrep_column: number): number
---@field _is_symfony_route_content fun(self: endpoint.SymfonyParser, content: string): boolean

---@class endpoint.ExpressParser : endpoint.Parser
---@field _is_express_route_content fun(self: endpoint.ExpressParser, content: string): boolean
---@field _detect_route_type fun(self: endpoint.ExpressParser, content: string): string
---@field _extract_app_type fun(self: endpoint.ExpressParser, content: string): string

---@class endpoint.NestJsParser : endpoint.Parser
---@field _is_nestjs_decorator_content fun(self: endpoint.NestJsParser, content: string): boolean
---@field _is_controller_decorator fun(self: endpoint.NestJsParser, content: string): boolean
---@field _extract_decorator_type fun(self: endpoint.NestJsParser, content: string): string
---@field _has_http_code_decorator fun(self: endpoint.NestJsParser, content: string): boolean
---@field _get_controller_path fun(self: endpoint.NestJsParser, file_path: string): string
---@field _combine_paths fun(self: endpoint.NestJsParser, base?: string, endpoint?: string): string

---@class endpoint.FastApiParser : endpoint.Parser
---@field _last_end_line_number number|nil
---@field _is_fastapi_decorator_content fun(self: endpoint.FastApiParser, content: string): boolean
---@field _extract_path_single_line fun(self: endpoint.FastApiParser, content: string): string|nil
---@field _extract_path_multiline fun(self: endpoint.FastApiParser, file_path: string, start_line: number, content: string): string|nil, number|nil
---@field _is_multiline_decorator fun(self: endpoint.FastApiParser, content: string): boolean
---@field _extract_decorator_type fun(self: endpoint.FastApiParser, content: string): string
---@field _find_router_prefix fun(self: endpoint.FastApiParser, file_path: string, line_number: number): string
---@field _infer_prefix_from_path fun(self: endpoint.FastApiParser, file_path: string): string
---@field _combine_paths fun(self: endpoint.FastApiParser, base?: string, endpoint?: string): string

---@class endpoint.DotNetParser : endpoint.Parser
---@field _last_end_line_number number|nil
---@field _is_dotnet_attribute_content fun(self: endpoint.DotNetParser, content: string): boolean
---@field _extract_route_info fun(self: endpoint.DotNetParser, content: string, file_path: string, line_number: number): string|nil, string|nil
---@field _extract_path_from_attributes fun(self: endpoint.DotNetParser, content: string): string|nil
---@field _extract_path_single_line fun(self: endpoint.DotNetParser, content: string, file_path?: string, line_number?: number): string|nil
---@field _extract_path_multiline fun(self: endpoint.DotNetParser, file_path: string, start_line: number, content: string): string|nil, number|nil
---@field _is_multiline_attribute fun(self: endpoint.DotNetParser, content: string): boolean
---@field _extract_methods_multiline fun(self: endpoint.DotNetParser, content: string, file_path: string, line_number: number): string[]
---@field _extract_method_from_attributes fun(self: endpoint.DotNetParser, content: string): string|nil
---@field _extract_method_from_surrounding_lines fun(self: endpoint.DotNetParser, file_path: string, line_number: number): string|nil
---@field _detect_attribute_type fun(self: endpoint.DotNetParser, content: string): string
---@field _has_route_template fun(self: endpoint.DotNetParser, content: string): boolean
---@field _get_controller_base_path fun(self: endpoint.DotNetParser, file_path: string, line_number: number): string
---@field _replace_controller_token fun(self: endpoint.DotNetParser, route_path: string, file_path: string, line_number: number): string
---@field _calculate_attribute_column fun(self: endpoint.DotNetParser, file_path: string, line_number: number, ripgrep_column: number): number
---@field _is_commented_code fun(self: endpoint.DotNetParser, content: string, file_path?: string, line_number?: number): boolean
---@field _clean_multiline_content fun(self: endpoint.DotNetParser, content: string): string
---@field _contains_unwanted_artifacts fun(self: endpoint.DotNetParser, content: string): boolean
---@field _is_class_level_route fun(self: endpoint.DotNetParser, content: string, file_path?: string, line_number?: number): boolean
---@field _combine_paths fun(self: endpoint.DotNetParser, base?: string, endpoint?: string): string

---@class endpoint.KtorParser : endpoint.Parser
---@field _is_valid_http_method fun(self: endpoint.KtorParser, method?: string): boolean
---@field _get_full_path fun(self: endpoint.KtorParser, path: string, file_path?: string, line_number?: number): string
---@field _extract_base_paths_from_file fun(self: endpoint.KtorParser, file_path: string, target_line: number): string[]
---@field _extract_path_single_line fun(self: endpoint.KtorParser, content: string): string|nil
---@field _extract_path_multiline fun(self: endpoint.KtorParser, file_path: string, start_line: number, content: string): string|nil, number|nil
---@field _is_multiline_routing fun(self: endpoint.KtorParser, content: string): boolean
---@field _last_end_line_number number|nil
---@field _looks_like_incomplete_ktor_routing fun(self: endpoint.KtorParser, content: string): boolean
---@field _get_extended_routing_content fun(self: endpoint.KtorParser, initial_content: string, file_path?: string, start_line?: number): string|nil

---@class endpoint.ServletParser : endpoint.Parser
---@field _is_servlet_content fun(self: endpoint.ServletParser, content: string): boolean
---@field _extract_webservlet_path fun(self: endpoint.ServletParser, content: string): string|nil
---@field _extract_servlet_method fun(self: endpoint.ServletParser, content: string): string|nil
---@field _detect_servlet_type fun(self: endpoint.ServletParser, content: string): string
---@field _has_web_xml_mapping fun(self: endpoint.ServletParser, file_path: string): boolean
---@field _find_servlet_mapping_for_file fun(self: endpoint.ServletParser, java_file_path: string): string[]|nil
---@field _find_webservlet_annotation_paths_for_file fun(self: endpoint.ServletParser, java_file_path: string): string[]|nil
---@field _extract_servlet_class_path fun(self: endpoint.ServletParser, content: string): string|nil

---@class endpoint.ReactRouterParser : endpoint.Parser
---@field _is_react_router_content fun(self: endpoint.ReactRouterParser, content: string): boolean
---@field _extract_route_path fun(self: endpoint.ReactRouterParser, content: string): string|nil
---@field _extract_component_name fun(self: endpoint.ReactRouterParser, content: string): string|nil
---@field _detect_route_type fun(self: endpoint.ReactRouterParser, content: string): string
---@field _find_component_file fun(self: endpoint.ReactRouterParser, component_name?: string): string|nil

-- ========================================
-- MANAGER CLASSES
-- ========================================

-- Cache Manager (OOP)
---@class endpoint.CacheManager : Class
---@field cached_endpoints endpoint.entry[]
---@field cache_timestamp number
---@field new fun(self: endpoint.CacheManager): endpoint.CacheManager
---@field is_valid fun(self: endpoint.CacheManager, method: string?): boolean
---@field get_endpoints fun(self: endpoint.CacheManager, method: string?): endpoint.entry[]
---@field save_endpoints fun(self: endpoint.CacheManager, endpoints: endpoint.entry[], method: string?)
---@field clear fun(self: endpoint.CacheManager)
---@field get_stats fun(self: endpoint.CacheManager): table

-- Event Manager (Observer Pattern)
---@class endpoint.EventManager : Class
---@field event_listeners table<string, endpoint.EventListener[]>
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
---@field available_pickers table<string, table>
---@field new fun(self: endpoint.PickerManager): endpoint.PickerManager
---@field _register_default_pickers fun(self: endpoint.PickerManager)
---@field get_picker fun(self: endpoint.PickerManager, picker_name: string): endpoint.Picker|nil
---@field get_all_pickers fun(self: endpoint.PickerManager): table<string, endpoint.Picker>
---@field register_picker fun(self: endpoint.PickerManager, picker_name: string, picker_instance: endpoint.Picker)
---@field is_picker_available fun(self: endpoint.PickerManager, picker_name: string): boolean
---@field get_best_available_picker fun(self: endpoint.PickerManager, preferred_picker_name?: string, fallback_picker_name?: string): endpoint.Picker, string

-- Endpoint Manager (Main Orchestrator)
---@class endpoint.EndpointManager : Class
---@field registered_frameworks endpoint.Framework[]
---@field event_manager endpoint.EventManager
---@field cache_manager endpoint.CacheManager
---@field picker_manager endpoint.PickerManager
---@field _initialized boolean
---@field new fun(self: endpoint.EndpointManager): endpoint.EndpointManager
---@field setup fun(self: endpoint.EndpointManager, user_config: table?)
---@field register_all_frameworks fun(self: endpoint.EndpointManager)
---@field register_framework fun(self: endpoint.EndpointManager, framework_instance: endpoint.Framework)
---@field unregister_framework fun(self: endpoint.EndpointManager, framework_name: string): boolean
---@field get_registered_frameworks fun(self: endpoint.EndpointManager): endpoint.Framework[]
---@field detect_project_frameworks fun(self: endpoint.EndpointManager): endpoint.Framework[]
---@field scan_all_endpoints fun(self: endpoint.EndpointManager, scan_options: table?): endpoint.entry[]
---@field scan_with_framework fun(self: endpoint.EndpointManager, framework_name: string, scan_options: table?): endpoint.entry[]
---@field get_event_manager fun(self: endpoint.EndpointManager): endpoint.EventManager
---@field add_event_listener fun(self: endpoint.EndpointManager, event_type: string, listener_callback: function, listener_priority: number?)
---@field remove_event_listener fun(self: endpoint.EndpointManager, event_type: string, listener_callback: function): boolean
---@field get_framework_info fun(self: endpoint.EndpointManager): table[]
---@field clear_all_frameworks fun(self: endpoint.EndpointManager): number
---@field find fun(self: endpoint.EndpointManager, opts: table?)
---@field clear_cache fun(self: endpoint.EndpointManager)
---@field show_cache_stats fun(self: endpoint.EndpointManager)
---@field _ensure_initialized fun(self: endpoint.EndpointManager)
---@field _show_with_picker fun(self: endpoint.EndpointManager, endpoints: endpoint.entry[], opts: table?)

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

---@class endpoint.ServletFramework : endpoint.Framework

---@class endpoint.ReactRouterFramework : endpoint.Framework

-- ========================================
-- CONCRETE PICKER IMPLEMENTATIONS
-- ========================================

---@class endpoint.TelescopePicker : endpoint.Picker
---@field telescope_available boolean
---@field highlighter endpoint.Highlighter
---@field initialize fun(self: endpoint.TelescopePicker)
---@field _set_preview_cursor fun(self: endpoint.TelescopePicker, picker_self: table, preview_line: number, preview_col: number)

---@class endpoint.SnacksPicker : endpoint.Picker
---@field snacks_available boolean
---@field highlighter endpoint.Highlighter
---@field initialize fun(self: endpoint.SnacksPicker)
---@field _validate_position fun(self: endpoint.SnacksPicker, endpoint: endpoint.entry): {start_pos: number[], end_pos: number[]}

---@class endpoint.VimUiSelectPicker : endpoint.Picker
---@field highlighter endpoint.Highlighter
---@field has_dressing boolean
---@field initialize fun(self: endpoint.VimUiSelectPicker)
---@field _create_telescope_entry fun(self: endpoint.VimUiSelectPicker, item: endpoint.entry, config: table): table
---@field _create_method_highlight_function fun(self: endpoint.VimUiSelectPicker): function
---@field _register_dressing_custom_kind fun(self: endpoint.VimUiSelectPicker)

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
