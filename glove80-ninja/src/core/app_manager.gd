class_name AppManager
extends Node

## Central application manager that handles service initialization and coordination

signal app_initialized()
signal services_ready()
signal app_shutting_down()

# Core services
var config_service: ConfigService
var user_service: UserService
var data_manager: DataManager

# Application state
var is_initialized: bool = false
var initialization_progress: float = 0.0
var services_ready_count: int = 0
var total_services: int = 2

# Service registry for dependency injection
var service_registry: Dictionary = {}

# Initialization steps
enum InitStep {
	CREATING_SERVICES,
	LOADING_CONFIG,
	INITIALIZING_USER_DATA,
	ENSURING_DIRECTORIES,
	CONNECTING_SIGNALS,
	FINALIZING
}

var current_init_step: InitStep = InitStep.CREATING_SERVICES


func _ready() -> void:
	Log.info("[AppManager][_ready] Starting application initialization...")
	await initialize_app()


## Initialize the entire application
func initialize_app() -> void:
	Log.info("[AppManager][initialize_app] Beginning application initialization")
	if is_initialized:
		Log.info("[AppManager][initialize_app] Application already initialized, skipping")
		return

	_set_init_step(InitStep.CREATING_SERVICES)
	await _create_core_services()

	_set_init_step(InitStep.ENSURING_DIRECTORIES)
	_ensure_data_directories()

	_set_init_step(InitStep.LOADING_CONFIG)
	await _initialize_config_service()

	_set_init_step(InitStep.INITIALIZING_USER_DATA)
	await _initialize_user_service()

	_set_init_step(InitStep.CONNECTING_SIGNALS)
	_connect_service_signals()

	_set_init_step(InitStep.FINALIZING)
	_register_services()
	_finalize_initialization()

	is_initialized = true
	initialization_progress = 100.0

	Log.info("[AppManager][initialize_app] Application initialization complete!")
	app_initialized.emit()
	services_ready.emit()


## Get a service by type
func get_service(p_service_type: String):
	Log.info("[AppManager][get_service] Requesting service: %s" % p_service_type)
	if service_registry.has(p_service_type):
		return service_registry[p_service_type]

	Log.error("[AppManager][get_service] Service not found: %s" % p_service_type)
	return null


## Get ConfigService instance
func get_config_service() -> ConfigService:
	return config_service


## Get UserService instance
func get_user_service() -> UserService:
	return user_service


## Check if all services are ready
func are_services_ready() -> bool:
	var services_are_ready = is_initialized and services_ready_count >= total_services
	if not services_are_ready:
		Log.info("[AppManager][are_services_ready] Services not ready - initialized: %s, count: %d/%d" % [is_initialized, services_ready_count, total_services])
	return services_are_ready


## Get initialization progress (0-100)
func get_initialization_progress() -> float:
	return initialization_progress


## Shutdown the application gracefully
func shutdown_app() -> void:
	Log.info("[AppManager][shutdown_app] Shutting down application...")
	app_shutting_down.emit()

	# Save any unsaved data
	if config_service and config_service.has_unsaved_changes():
		config_service.save_all_configs()
		Log.info("[AppManager][shutdown_app] Configuration saved on shutdown")

	if user_service:
		user_service.save_profile()
		Log.info("[AppManager][shutdown_app] User profile saved on shutdown")

	_cleanup_temp_files()

	Log.info("[AppManager][shutdown_app] Shutdown complete")


func create_practice_controller() -> PracticeController:
	Log.info("[AppManager][create_practice_controller] Creating practice controller")
	if not are_services_ready():
		Log.error("[AppManager][create_practice_controller] Cannot create PracticeController: Services not ready")
		return null

	var practice_scene = load("res://src/practice/practice_controller.tscn")
	if not practice_scene:
		Log.error("[AppManager][create_practice_controller] Could not load practice controller scene")
		return null

	var practice_controller = practice_scene.instantiate()
	practice_controller.initialize(config_service, user_service)
	Log.info("[AppManager][create_practice_controller] Practice controller created successfully")
	return practice_controller


func create_settings_controller() -> Control:
	Log.info("[AppManager][create_settings_controller] Creating settings controller")
	if not config_service:
		Log.error("[AppManager][create_settings_controller] Cannot create SettingsController: ConfigService not available")
		return null

	var settings_scene = load("res://src/settings/settings_controller.tscn")
	if not settings_scene:
		Log.error("[AppManager][create_settings_controller] Could not load settings controller scene")
		return null

	var settings_controller = settings_scene.instantiate()
	settings_controller.initialize(config_service)
	Log.info("[AppManager][create_settings_controller] Settings controller created successfully")
	return settings_controller


## Export application data for backup
func export_app_data(p_export_path: String) -> bool:
	Log.info("[AppManager][export_app_data] Exporting app data to: %s" % p_export_path)
	if not DataManager.is_valid_user_data_path(p_export_path):
		Log.error("[AppManager][export_app_data] Invalid export path: %s" % p_export_path)
		return false

	var export_data = {
		"timestamp": Time.get_datetime_string_from_system(),
		"app_version": config_service.get_setting("app_version", "1.0.0") if config_service else "unknown",
		"user_config": config_service.get_user_config() if config_service else {},
		"user_profile": user_service.get_profile() if user_service else {}
	}

	var success = DataManager.save_json(p_export_path, export_data)
	if success:
		Log.info("[AppManager][export_app_data] App data exported successfully")
	else:
		Log.error("[AppManager][export_app_data] Failed to export app data")

	return success


## Import application data from backup
func import_app_data(p_import_path: String) -> bool:
	Log.info("[AppManager][import_app_data] Importing app data from: %s" % p_import_path)
	if not FileAccess.file_exists(p_import_path):
		Log.error("[AppManager][import_app_data] Import file does not exist: %s" % p_import_path)
		return false

	var imported_data = DataManager.load_json(p_import_path, {})
	if imported_data.is_empty():
		Log.error("[AppManager][import_app_data] Failed to load import data")
		return false

	var success = true

	# Import user config if available
	if imported_data.has("user_config") and config_service:
		Log.info("[AppManager][import_app_data] Importing user configuration")
		for key in imported_data.user_config:
			config_service.set_user_setting(key, imported_data.user_config[key])
		if not config_service.save_user_config():
			Log.error("[AppManager][import_app_data] Failed to save imported user configuration")
			success = false

	# Import user profile if available (this is more complex, so we use the service method)
	if imported_data.has("user_profile") and user_service:
		Log.info("[AppManager][import_app_data] Importing user profile")
		# Save current profile as backup first
		DataManager.create_backup(DataManager.DEFAULT_PROFILE)
		# This would need a proper import method in UserService
		# For now, we'll skip this part

	if success:
		Log.info("[AppManager][import_app_data] App data imported successfully")
	else:
		Log.error("[AppManager][import_app_data] Some import operations failed")

	return success


# Private methods

func _create_core_services() -> void:
	Log.info("[AppManager][_create_core_services] Creating core services...")

	# Create services
	config_service = ConfigService.new()
	user_service = UserService.new()

	# Note: DataManager is static, so we don't need to instantiate it
	data_manager = null  # Placeholder for consistency

	initialization_progress = 20.0
	Log.info("[AppManager][_create_core_services] Core services created")
	await get_tree().process_frame  # Allow UI to update


func _ensure_data_directories() -> void:
	Log.info("[AppManager][_ensure_data_directories] Ensuring data directories exist...")
	DataManager.ensure_directories()
	initialization_progress = 30.0
	Log.info("[AppManager][_ensure_data_directories] Data directories verified")


func _initialize_config_service() -> void:
	Log.info("[AppManager][_initialize_config_service] Initializing configuration service...")

	if config_service:
		config_service.initialize()
		await _wait_for_service_ready("config")
		services_ready_count += 1
		Log.info("[AppManager][_initialize_config_service] ConfigService initialized successfully")
	else:
		Log.error("[AppManager][_initialize_config_service] ConfigService is null")

	initialization_progress = 60.0


func _initialize_user_service() -> void:
	Log.info("[AppManager][_initialize_user_service] Initializing user service...")

	if user_service:
		user_service.initialize()
		await _wait_for_service_ready("user")
		services_ready_count += 1
		Log.info("[AppManager][_initialize_user_service] UserService initialized successfully")
	else:
		Log.error("[AppManager][_initialize_user_service] UserService is null")

	initialization_progress = 80.0


func _connect_service_signals() -> void:
	Log.info("[AppManager][_connect_service_signals] Connecting service signals...")

	# Connect config service signals
	if config_service:
		config_service.config_loaded.connect(_on_config_loaded)
		config_service.config_saved.connect(_on_config_saved)
		config_service.setting_changed.connect(_on_setting_changed)
		Log.info("[AppManager][_connect_service_signals] ConfigService signals connected")

	# Connect user service signals
	if user_service:
		user_service.profile_loaded.connect(_on_profile_loaded)
		user_service.profile_saved.connect(_on_profile_saved)
		user_service.achievement_unlocked.connect(_on_achievement_unlocked)
		Log.info("[AppManager][_connect_service_signals] UserService signals connected")

	initialization_progress = 90.0


func _register_services() -> void:
	Log.info("[AppManager][_register_services] Registering services...")

	service_registry["config"] = config_service
	service_registry["user"] = user_service
	service_registry["data"] = data_manager  # Even though it's static

	# Register self as the main app manager
	service_registry["app"] = self

	Log.info("[AppManager][_register_services] Registered %d services" % service_registry.size())


func _finalize_initialization() -> void:
	Log.info("[AppManager][_finalize_initialization] Finalizing initialization...")

	# Perform any final setup tasks
	_setup_default_settings()
	_check_first_run()

	initialization_progress = 95.0
	Log.info("[AppManager][_finalize_initialization] Initialization finalized")


func _setup_default_settings() -> void:
	if not config_service:
		Log.error("[AppManager][_setup_default_settings] ConfigService not available")
		return

	Log.info("[AppManager][_setup_default_settings] Setting up default settings")
	# Set up any required default settings that haven't been set
	var required_defaults = {
		"first_run": false,
		"app_version": "1.0.0",
		"last_startup": Time.get_datetime_string_from_system()
	}

	for key in required_defaults:
		if config_service.get_setting(key) == null:
			config_service.set_app_setting(key, required_defaults[key])
			Log.info("[AppManager][_setup_default_settings] Set default for %s" % key)


func _check_first_run() -> void:
	if not config_service:
		Log.error("[AppManager][_check_first_run] ConfigService not available")
		return

	var is_first_run = config_service.get_setting("first_run", true)
	if is_first_run:
		Log.info("[AppManager][_check_first_run] First run detected - setting up defaults")
		_setup_first_run_defaults()
		config_service.set_app_setting("first_run", false, true)
	else:
		Log.info("[AppManager][_check_first_run] Not a first run")


func _setup_first_run_defaults() -> void:
	Log.info("[AppManager][_setup_first_run_defaults] Setting up first run defaults")
	# Set up defaults for first-time users
	if config_service:
		config_service.set_user_setting("cursor_style", "block")
		config_service.set_user_setting("theme", "dark")
		config_service.set_user_setting("font_size", 16)
		Log.info("[AppManager][_setup_first_run_defaults] Default user settings configured")

	# Could also show a welcome tutorial here
	Log.info("[AppManager][_setup_first_run_defaults] First run setup complete")


func _wait_for_service_ready(p_service_name: String) -> void:
	Log.info("[AppManager][_wait_for_service_ready] Waiting for %s service to be ready" % p_service_name)
	# Simple wait - in a real implementation, you might want to wait for specific signals
	await get_tree().create_timer(0.1).timeout
	Log.info("[AppManager][_wait_for_service_ready] %s service ready" % p_service_name)


func _set_init_step(p_step: InitStep) -> void:
	current_init_step = p_step
	var step_names = ["Creating Services", "Loading Config", "Initializing User Data",
					  "Ensuring Directories", "Connecting Signals", "Finalizing"]
	if p_step < step_names.size():
		Log.info("[AppManager][_set_init_step] %s..." % step_names[p_step])


func _cleanup_temp_files() -> void:
	Log.info("[AppManager][_cleanup_temp_files] Cleaning up temporary files")
	# Clean up any temporary files created during the session
	var temp_files = DataManager.list_files(DataManager.CACHE_DIR, "tmp")
	for temp_file in temp_files:
		DataManager.delete_file(temp_file, false)  # Don't create backup for temp files
	Log.info("[AppManager][_cleanup_temp_files] Cleaned up %d temporary files" % temp_files.size())


# Signal handlers

func _on_config_loaded() -> void:
	Log.info("[AppManager][_on_config_loaded] Configuration loaded")


func _on_config_saved() -> void:
	Log.info("[AppManager][_on_config_saved] Configuration saved")


func _on_setting_changed(p_setting_name: String, p_new_value) -> void:
	Log.info("[AppManager][_on_setting_changed] Setting changed - %s: %s" % [p_setting_name, p_new_value])

	# Handle important setting changes
	match p_setting_name:
		"theme":
			_apply_app_theme(p_new_value)
		"language":
			_change_app_language(p_new_value)


func _on_profile_loaded() -> void:
	Log.info("[AppManager][_on_profile_loaded] User profile loaded")


func _on_profile_saved() -> void:
	Log.info("[AppManager][_on_profile_saved] User profile saved")


func _on_achievement_unlocked(p_achievement_id: String) -> void:
	Log.info("[AppManager][_on_achievement_unlocked] Achievement unlocked - %s" % p_achievement_id)
	# Could trigger UI notifications here


func _apply_app_theme(p_theme_name: String) -> void:
	Log.info("[AppManager][_apply_app_theme] Applying theme - %s" % p_theme_name)
	# TODO: Implementation would apply theme to the entire application


func _change_app_language(p_language_code: String) -> void:
	Log.info("[AppManager][_change_app_language] Changing language - %s" % p_language_code)
    # TODO: Implementation would change the application language


# Static convenience methods for global access

static func get_instance() -> AppManager:
	var main_scene = Engine.get_main_loop().current_scene
	if main_scene and main_scene.has_method("get_app_manager"):
		return main_scene.get_app_manager()

	# Fallback: search for AppManager in the scene tree
	var app_manager = main_scene.get_tree().get_first_node_in_group("app_manager")
	if app_manager and app_manager is AppManager:
		return app_manager as AppManager

	return null


static func get_config() -> ConfigService:
	var instance = get_instance()
	return instance.get_config_service() if instance else null


static func get_user() -> UserService:
	var instance = get_instance()
	return instance.get_user_service() if instance else null
