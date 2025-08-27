class_name AppManager
extends Node

## Central application manager that handles service initialization and coordination
## Replaces multiple autoloads with a single, well-organized service container

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
	print("AppManager: Starting application initialization...")
	await initialize_app()


## Initialize the entire application
func initialize_app() -> void:
	if is_initialized:
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

	print("AppManager: Application initialization complete!")
	app_initialized.emit()
	services_ready.emit()


## Get a service by type
func get_service(service_type: String):
	if service_registry.has(service_type):
		return service_registry[service_type]

	push_error("Service not found: " + service_type)
	return null


## Get ConfigService instance
func get_config_service() -> ConfigService:
	return config_service


## Get UserService instance
func get_user_service() -> UserService:
	return user_service


## Check if all services are ready
func are_services_ready() -> bool:
	return is_initialized and services_ready_count >= total_services


## Get initialization progress (0-100)
func get_initialization_progress() -> float:
	return initialization_progress


## Shutdown the application gracefully
func shutdown_app() -> void:
	print("AppManager: Shutting down application...")
	app_shutting_down.emit()

	# Save any unsaved data
	if config_service and config_service.has_unsaved_changes():
		config_service.save_all_configs()
		print("AppManager: Configuration saved on shutdown")

	if user_service:
		user_service.save_profile()
		print("AppManager: User profile saved on shutdown")

	# Clean up temporary files
	_cleanup_temp_files()

	print("AppManager: Shutdown complete")


## Create a new PracticeController with proper dependency injection
func create_practice_controller() -> PracticeControllerRefactored:
	if not are_services_ready():
		push_error("Cannot create PracticeController: Services not ready")
		return null

	var practice_scene = load("res://src/practice/practice_controller.tscn")
	if not practice_scene:
		push_error("Could not load practice controller scene")
		return null
	var practice_controller = practice_scene.instantiate()
	practice_controller.initialize(config_service, user_service)
	return practice_controller


## Create settings controller with dependency injection
func create_settings_controller() -> Control:
	if not config_service:
		push_error("Cannot create SettingsController: ConfigService not available")
		return null

	var settings_scene = load("res://src/settings/settings_controller.tscn")
	if not settings_scene:
		push_error("Could not load settings controller scene")
		return null
	var settings_controller = settings_scene.instantiate()
	settings_controller.initialize(config_service)
	return settings_controller


## Export application data for backup
func export_app_data(export_path: String) -> bool:
	if not DataManager.is_valid_user_data_path(export_path):
		push_error("Invalid export path: " + export_path)
		return false

	var export_data = {
		"timestamp": Time.get_datetime_string_from_system(),
		"app_version": config_service.get_setting("app_version", "1.0.0") if config_service else "unknown",
		"user_config": config_service.get_user_config() if config_service else {},
		"user_profile": user_service.get_profile() if user_service else {}
	}

	return DataManager.save_json(export_path, export_data)


## Import application data from backup
func import_app_data(import_path: String) -> bool:
	if not FileAccess.file_exists(import_path):
		push_error("Import file does not exist: " + import_path)
		return false

	var imported_data = DataManager.load_json(import_path, {})
	if imported_data.is_empty():
		push_error("Failed to load import data")
		return false

	var success = true

	# Import user config if available
	if imported_data.has("user_config") and config_service:
		for key in imported_data.user_config:
			config_service.set_user_setting(key, imported_data.user_config[key])
		if not config_service.save_user_config():
			success = false

	# Import user profile if available (this is more complex, so we use the service method)
	if imported_data.has("user_profile") and user_service:
		# Save current profile as backup first
		DataManager.create_backup(DataManager.DEFAULT_PROFILE)
		# This would need a proper import method in UserService
		# For now, we'll skip this part

	return success


# Private methods

func _create_core_services() -> void:
	print("AppManager: Creating core services...")

	# Create services
	config_service = ConfigService.new()
	user_service = UserService.new()

	# Note: DataManager is static, so we don't need to instantiate it
	data_manager = null  # Placeholder for consistency

	initialization_progress = 20.0
	await get_tree().process_frame  # Allow UI to update


func _ensure_data_directories() -> void:
	print("AppManager: Ensuring data directories exist...")
	DataManager.ensure_directories()
	initialization_progress = 30.0


func _initialize_config_service() -> void:
	print("AppManager: Initializing configuration service...")

	if config_service:
		config_service.initialize()
		await _wait_for_service_ready("config")
		services_ready_count += 1

	initialization_progress = 60.0


func _initialize_user_service() -> void:
	print("AppManager: Initializing user service...")

	if user_service:
		user_service.initialize()
		await _wait_for_service_ready("user")
		services_ready_count += 1

	initialization_progress = 80.0


func _connect_service_signals() -> void:
	print("AppManager: Connecting service signals...")

	# Connect config service signals
	if config_service:
		config_service.config_loaded.connect(_on_config_loaded)
		config_service.config_saved.connect(_on_config_saved)
		config_service.setting_changed.connect(_on_setting_changed)

	# Connect user service signals
	if user_service:
		user_service.profile_loaded.connect(_on_profile_loaded)
		user_service.profile_saved.connect(_on_profile_saved)
		user_service.achievement_unlocked.connect(_on_achievement_unlocked)

	initialization_progress = 90.0


func _register_services() -> void:
	print("AppManager: Registering services...")

	service_registry["config"] = config_service
	service_registry["user"] = user_service
	service_registry["data"] = data_manager  # Even though it's static

	# Register self as the main app manager
	service_registry["app"] = self


func _finalize_initialization() -> void:
	print("AppManager: Finalizing initialization...")

	# Perform any final setup tasks
	_setup_default_settings()
	_check_first_run()

	initialization_progress = 95.0


func _setup_default_settings() -> void:
	if not config_service:
		return

	# Set up any required default settings that haven't been set
	var required_defaults = {
		"first_run": false,
		"app_version": "1.0.0",
		"last_startup": Time.get_datetime_string_from_system()
	}

	for key in required_defaults:
		if config_service.get_setting(key) == null:
			config_service.set_app_setting(key, required_defaults[key])


func _check_first_run() -> void:
	if not config_service:
		return

	var is_first_run = config_service.get_setting("first_run", true)
	if is_first_run:
		print("AppManager: First run detected - setting up defaults")
		_setup_first_run_defaults()
		config_service.set_app_setting("first_run", false, true)


func _setup_first_run_defaults() -> void:
	# Set up defaults for first-time users
	if config_service:
		config_service.set_user_setting("cursor_style", "block")
		config_service.set_user_setting("theme", "dark")
		config_service.set_user_setting("font_size", 16)

	# Could also show a welcome tutorial here
	print("AppManager: First run setup complete")


func _wait_for_service_ready(service_name: String) -> void:
	# Simple wait - in a real implementation, you might want to wait for specific signals
	await get_tree().create_timer(0.1).timeout
	print("AppManager: %s service ready" % service_name)


func _set_init_step(step: InitStep) -> void:
	current_init_step = step
	var step_names = ["Creating Services", "Loading Config", "Initializing User Data",
					  "Ensuring Directories", "Connecting Signals", "Finalizing"]
	if step < step_names.size():
		print("AppManager: %s..." % step_names[step])


func _cleanup_temp_files() -> void:
	# Clean up any temporary files created during the session
	var temp_files = DataManager.list_files(DataManager.CACHE_DIR, "tmp")
	for temp_file in temp_files:
		DataManager.delete_file(temp_file, false)  # Don't create backup for temp files


# Signal handlers

func _on_config_loaded() -> void:
	print("AppManager: Configuration loaded")


func _on_config_saved() -> void:
	print("AppManager: Configuration saved")


func _on_setting_changed(setting_name: String, new_value) -> void:
	print("AppManager: Setting changed - %s: %s" % [setting_name, new_value])

	# Handle important setting changes
	match setting_name:
		"theme":
			_apply_app_theme(new_value)
		"language":
			_change_app_language(new_value)


func _on_profile_loaded() -> void:
	print("AppManager: User profile loaded")


func _on_profile_saved() -> void:
	print("AppManager: User profile saved")


func _on_achievement_unlocked(achievement_id: String) -> void:
	print("AppManager: Achievement unlocked - %s" % achievement_id)
	# Could trigger UI notifications here


func _apply_app_theme(theme_name: String) -> void:
	print("AppManager: Applying theme - %s" % theme_name)
	# Implementation would apply theme to the entire application


func _change_app_language(language_code: String) -> void:
	print("AppManager: Changing language - %s" % language_code)
	# Implementation would change the application language


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
