class_name Settings
extends Node

signal settings_updated

var _settings: Dictionary
var _is_initialized: bool = false


func initialize() -> void:
	if _is_initialized:
		return

	Log.info("≥≥≥ [UserSettings][initialize] :: START :: Initialization of USER SETTINGS")
	_register_signals()
	_load_settings()
	_is_initialized = true
	Log.info("<<< [UserSettings][initialize] :: FINISH :: Initialization of USER SETTINGS")


func get_settings() -> Dictionary:
	return _settings


func save(p_settings: Dictionary) -> void:
	Log.info("[UserSettings][save] Saving settings.")
	DataManager.save_json(_fmt_path(), p_settings)
	settings_updated.emit()


func _register_signals() -> void:
	if not UserService.profile_loaded.is_connected(_load_settings):
		UserService.profile_loaded.connect(_load_settings)


func _fmt_path() -> String:
	return UserService.get_user_dir() + "/" + User.FILE_SETTINGS


func _load_settings() -> void:
	_settings = DataManager.load_json(_fmt_path(), User.DEFAULT_USER_SETTINGS)
	for setting_name in User.DEFAULT_USER_SETTINGS:
		if not _settings.has(setting_name):
			_settings[setting_name] = User.DEFAULT_USER_SETTINGS[setting_name]
	Log.info("[UserSettings][load_settings] User settings loaded.")
