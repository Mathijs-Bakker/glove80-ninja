class_name ConfigService
extends RefCounted

## Unified configuration service that replaces ConfigManager and UserConfigManager
## Handles all application and user settings with proper separation of concerns


signal config_loaded()
signal config_saved()
signal setting_changed(setting_name: String, new_value)

# Configuration file paths
const APP_CONFIG_PATH = "user://data/config/app_config.json"
const USER_CONFIG_PATH = "user://data/config/user_config.json"

# Default configurations
const DEFAULT_APP_CONFIG = {
	"app_version": "1.0.0",
	"debug_mode": false,
	"log_level": "INFO"
}

const DEFAULT_USER_CONFIG = {
	"cursor_style": "block",
	"theme": "dark",
	"font_size": 16,
	"sound_volume": 80,
	"typing_sounds": true,
	"language": "en",
	"auto_save": true,
	"show_wpm": true,
	"show_accuracy": true
}

# Internal state
var _app_config: Dictionary = {}
var _user_config: Dictionary = {}
var _unsaved_changes: Dictionary = {}
var _is_loaded: bool = false


## Initialize the configuration service
func initialize() -> void:
	DataManager.ensure_directories()
	load_all_configs()


## Load all configuration files
func load_all_configs() -> void:
	_load_app_config()
	_load_user_config()
	_is_loaded = true
	config_loaded.emit()


## Save all configurations
func save_all_configs() -> bool:
	var app_saved = _save_app_config()
	var user_saved = _save_user_config()

	if app_saved and user_saved:
		_unsaved_changes.clear()
		config_saved.emit()
		return true

	return false


## Get a setting value (checks user config first, then app config)
func get_setting(setting_name: String, default_value = null):
	# Check unsaved changes first
	if _unsaved_changes.has(setting_name):
		return _unsaved_changes[setting_name]

	# Check user config
	if _user_config.has(setting_name):
		return _user_config[setting_name]

	# Check app config
	if _app_config.has(setting_name):
		return _app_config[setting_name]

	# Check defaults
	if DEFAULT_USER_CONFIG.has(setting_name):
		return DEFAULT_USER_CONFIG[setting_name]

	if DEFAULT_APP_CONFIG.has(setting_name):
		return DEFAULT_APP_CONFIG[setting_name]

	return default_value


## Set a user setting
func set_user_setting(setting_name: String, value, save_immediately: bool = false) -> void:
	var current_value = get_setting(setting_name)

	if current_value == value:
		return  # No change needed

	_unsaved_changes[setting_name] = value
	setting_changed.emit(setting_name, value)

	if save_immediately:
		save_user_config()


## Set an app setting (typically used by the application, not user)
func set_app_setting(setting_name: String, value, save_immediately: bool = false) -> void:
	_app_config[setting_name] = value

	if save_immediately:
		_save_app_config()


## Get user configuration dictionary
func get_user_config() -> Dictionary:
	var config = _user_config.duplicate(true)
	# Apply unsaved changes
	for key in _unsaved_changes:
		if _is_user_setting(key):
			config[key] = _unsaved_changes[key]
	return config


## Get app configuration dictionary
func get_app_config() -> Dictionary:
	return _app_config.duplicate(true)


## Check if there are unsaved changes
func has_unsaved_changes() -> bool:
	return not _unsaved_changes.is_empty()


## Discard unsaved changes
func discard_unsaved_changes() -> void:
	_unsaved_changes.clear()


## Reset user configuration to defaults
func reset_user_config_to_defaults(save_immediately: bool = true) -> void:
	_user_config = DEFAULT_USER_CONFIG.duplicate(true)
	_unsaved_changes.clear()

	if save_immediately:
		save_user_config()


## Reset app configuration to defaults
func reset_app_config_to_defaults(save_immediately: bool = true) -> void:
	_app_config = DEFAULT_APP_CONFIG.duplicate(true)

	if save_immediately:
		_save_app_config()


## Save only user configuration
func save_user_config() -> bool:
	# Apply unsaved user changes
	for key in _unsaved_changes:
		if _is_user_setting(key):
			_user_config[key] = _unsaved_changes[key]

	# Remove applied changes
	var keys_to_remove = []
	for key in _unsaved_changes:
		if _is_user_setting(key):
			keys_to_remove.append(key)

	for key in keys_to_remove:
		_unsaved_changes.erase(key)

	return _save_user_config()


## Export user configuration for backup
func export_user_config(export_path: String) -> bool:
	var export_data = get_user_config()
	return DataManager.save_json(export_path, export_data)


## Import user configuration from backup
func import_user_config(import_path: String) -> bool:
	if not FileAccess.file_exists(import_path):
		push_error("Import file does not exist: " + import_path)
		return false

	var imported_config = DataManager.load_json(import_path, {})
	if imported_config.is_empty():
		push_error("Failed to load import file or file is empty")
		return false

	_user_config = imported_config
	_unsaved_changes.clear()
	return save_user_config()


## Get configuration summary for debugging
func get_config_summary() -> Dictionary:
	return {
		"is_loaded": _is_loaded,
		"app_settings_count": _app_config.size(),
		"user_settings_count": _user_config.size(),
		"unsaved_changes_count": _unsaved_changes.size(),
		"unsaved_changes": _unsaved_changes.keys()
	}


# Private methods

func _load_app_config() -> void:
	_app_config = DataManager.load_json(APP_CONFIG_PATH, DEFAULT_APP_CONFIG)


func _load_user_config() -> void:
	_user_config = DataManager.load_json(USER_CONFIG_PATH, DEFAULT_USER_CONFIG)


func _save_app_config() -> bool:
	return DataManager.save_json(APP_CONFIG_PATH, _app_config)


func _save_user_config() -> bool:
	return DataManager.save_json(USER_CONFIG_PATH, _user_config)


func _is_user_setting(setting_name: String) -> bool:
	return DEFAULT_USER_CONFIG.has(setting_name) or not DEFAULT_APP_CONFIG.has(setting_name)
