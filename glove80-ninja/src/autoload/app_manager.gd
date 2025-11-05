extends Node

signal app_initialized
signal services_ready
signal app_shutting_down

# Application state
var is_initialized: bool = false
var services_ready_count: int = 0
var total_services: int = 2


func _ready() -> void:
	_initialize_app()


func _initialize_app() -> void:
	Log.info("[app_manager][_initialize_app] Start initializing application")

	DataManager.ensure_directories_exist()
	UserService.initialize()
	_connect_service_signals()
	# _finalize_initialization()

	is_initialized = true

	Log.info("[AppManager][_initialize_app] Application initialization completed")
	await get_tree().create_timer(0.1).timeout
	app_initialized.emit()
	services_ready.emit()


func shutdown_gracefully() -> void:
	Log.info("[AppManager][shutdown_gracefully] Shutting down application...")
	app_shutting_down.emit()

	# Save any unsaved data
	if ConfigService and ConfigService.has_unsaved_changes():
		ConfigService.save_all_configs()
		Log.info("[AppManager][shutdown_gracefully] Configuration saved on shutdown")

	if UserService:
		UserService.save_profile()
		Log.info("[AppManager][shutdown_gracefully] User profile saved on shutdown")

	# _cleanup_temp_files()

	Log.info("[AppManager][shutdown_gracefully] Shutdown complete")


func _connect_service_signals() -> void:
	ConfigService.config_loaded.connect(_on_config_loaded)
	ConfigService.config_saved.connect(_on_config_saved)
	ConfigService.setting_changed.connect(_on_setting_changed)

	UserService.profile_loaded.connect(_on_profile_loaded)
	UserService.profile_saved.connect(_on_profile_saved)
	UserService.achievement_unlocked.connect(_on_achievement_unlocked)


func _finalize_initialization() -> void:
	Log.info("[AppManager][_finalize_initialization] Finalizing initialization...")

	# Perform any final setup tasks
	# _setup_default_settings()
	# _check_first_run()

	Log.info("[AppManager][_finalize_initialization] Initialization finalized")


# func _setup_default_settings() -> void:
# 	Log.info("[AppManager][_setup_default_settings] Setting up default settings")
# 	# Set up any required default settings that haven't been set
# 	var required_defaults = {
# 		"first_run": false,
# 		"app_version": "1.0.0",
# 		"last_startup": Time.get_datetime_string_from_system()
# 	}

# 	for key in required_defaults:
# 		if ConfigService.get_setting(key) == null:
# 			ConfigService.set_app_setting(key, required_defaults[key])
# 			Log.info("[AppManager][_setup_default_settings] Set default for %s" % key)

# func _check_first_run() -> void:
# 	if not ConfigService:
# 		Log.error("[AppManager][_check_first_run] ConfigService not available")
# 		return

# 	var is_first_run = ConfigService.get_setting("first_run", true)
# 	if is_first_run:
# 		Log.info("[AppManager][_check_first_run] First run detected - setting up defaults")
# 		_setup_first_run_defaults()
# 		ConfigService.set_app_setting("first_run", false, true)
# 	else:
# 		Log.info("[AppManager][_check_first_run] Not a first run")


func _setup_first_run_defaults() -> void:
	Log.info("[AppManager][_setup_first_run_defaults] Setting up first run defaults")
	# Set up defaults for first-time users
	if ConfigService:
		ConfigService.set_user_setting("cursor_style", "block")
		ConfigService.set_user_setting("theme", "dark")
		ConfigService.set_user_setting("font_size", 16)
		(
			Log
			. info(
				"[AppManager][_setulist_files_with_extension_filtern_defaults] Default user settings configured"
			)
		)

	# Could also show a welcome tutorial here
	Log.info("[AppManager][_setup_first_run_defaults] First run setup complete")


# func _wait_for_service_ready(p_service_name: String) -> void:
# 	Log.info(
# 		"[AppManager][_wait_for_service_ready] Waiting for %s service to be ready" % p_service_name
# 	)
# 	# Simple wait - in a real implementation, you might want to wait for specific signals
# 	await get_tree().create_timer(0.1).timeout
# 	Log.info("[AppManager][_wait_for_service_ready] %s service ready" % p_service_name)

# func _cleanup_temp_files() -> void:
# 	Log.info("[AppManager][_cleanup_temp_files] Cleaning up temporary files")
# 	# Clean up any temporary files created during the session
# 	var temp_files = DataManager.list_files(DataManager.CACHE_DIR, "tmp")
# 	for temp_file in temp_files:
# 		DataManager.delete_file(temp_file, false)  # Don't create backup for temp files
# 	Log.info("[AppManager][_cleanup_temp_files] Cleaned up %d temporary files" % temp_files.size())

# Signal handlers


func _on_config_loaded() -> void:
	Log.info("[AppManager][_on_config_loaded] Configuration loaded")


func _on_config_saved() -> void:
	Log.info("[AppManager][_on_config_saved] Configuration saved")


func _on_setting_changed(p_setting_name: String, p_new_value) -> void:
	Log.info(
		"[AppManager][_on_setting_changed] Setting changed - %s: %s" % [p_setting_name, p_new_value]
	)

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

# func get_instance() -> AppManager:
# 	var main_scene = Engine.get_main_loop().current_scene
# 	if main_scene and main_scene.has_method("get_app_manager"):
# 		return main_scene.get_app_manager()

# 	# Fallback: search for AppManager in the scene tree
# 	var app_manager = main_scene.get_tree().get_first_node_in_group("app_manager")
# 	if app_manager and app_manager is AppManager:
# 		return app_manager as AppManager

# 	return null

# func get_user() -> UserService:
# 	var instance = get_instance()
# 	return instance.get_user_service() if instance else null
