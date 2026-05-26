extends Node

signal app_initialized
signal services_ready
signal app_shutting_down

# Application state
var services_ready_count: int = 0
var total_services: int = 2


func _ready() -> void:
	_initialize_application()


func _initialize_application() -> void:
	Log.info(">>> [AppManager][initialize_application] :: START :: Initialize application.")
	if not UserService.users_file_exist():
		var first_run = FirstRunSetup.new()
		first_run.run_setup_async()
		Log.info("[AppManager][initialize_application] First run setup complete.")

	UserService.initialize()
	UserSettings.initialize()
	_connect_service_signals()

	Log.info(
		"<<< [AppManager][_initialize_application] :: END ::  initialization of the application."
	)
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
