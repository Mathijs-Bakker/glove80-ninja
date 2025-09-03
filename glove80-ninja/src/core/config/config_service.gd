class_name ConfigService
extends RefCounted

## Unified configuration service that replaces ConfigManager and UserConfigManager
## Handles all application and user settings with proper separation of concerns


signal config_loaded()
signal config_saved()
signal setting_changed(p_setting_name: String, p_new_value)

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
	"font_size": 40,
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
	Log.info("[ConfigService][initialize] Initializing configuration service")
	DataManager.ensure_directories()
	load_all_configs()
	Log.info("[ConfigService][initialize] Configuration service initialized successfully")


## Load all configuration files
func load_all_configs() -> void:
	Log.info("[ConfigService][load_all_configs] Loading all configuration files")
	_load_app_config()
	_load_user_config()
	_is_loaded = true
	Log.info("[ConfigService][load_all_configs] All configurations loaded successfully")
	config_loaded.emit()


## Save all configurations
func save_all_configs() -> bool:
	Log.info("[ConfigService][save_all_configs] Saving all configurations")
	var app_saved = _save_app_config()
	var user_saved = _save_user_config()

	if app_saved and user_saved:
		_unsaved_changes.clear()
		Log.info("[ConfigService][save_all_configs] All configurations saved successfully")
		config_saved.emit()
		return true

	Log.error("[ConfigService][save_all_configs] Failed to save configurations - app_saved: %s, user_saved: %s" % [app_saved, user_saved])
	return false


## Get a setting value (checks user config first, then app config)
func get_setting(p_setting_name: String, p_default_value = null):
	Log.info("[ConfigService][get_setting] Getting setting: %s" % p_setting_name)

	# Check unsaved changes first
	if _unsaved_changes.has(p_setting_name):
		Log.info("[ConfigService][get_setting] Found unsaved value for %s" % p_setting_name)
		return _unsaved_changes[p_setting_name]

	# Check user config
	if _user_config.has(p_setting_name):
		Log.info("[ConfigService][get_setting] Found user config value for %s" % p_setting_name)
		return _user_config[p_setting_name]

	# Check app config
	if _app_config.has(p_setting_name):
		Log.info("[ConfigService][get_setting] Found app config value for %s" % p_setting_name)
		return _app_config[p_setting_name]

	# Check defaults
	if DEFAULT_USER_CONFIG.has(p_setting_name):
		Log.info("[ConfigService][get_setting] Using user default for %s" % p_setting_name)
		return DEFAULT_USER_CONFIG[p_setting_name]

	if DEFAULT_APP_CONFIG.has(p_setting_name):
		Log.info("[ConfigService][get_setting] Using app default for %s" % p_setting_name)
		return DEFAULT_APP_CONFIG[p_setting_name]

	Log.info("[ConfigService][get_setting] No value found for %s, returning default" % p_setting_name)
	return p_default_value


## Set a user setting
func set_user_setting(p_setting_name: String, p_value, p_save_immediately: bool = false) -> void:
	Log.info("[ConfigService][set_user_setting] Setting user setting: %s = %s" % [p_setting_name, p_value])
	var current_value = get_setting(p_setting_name)

	if current_value == p_value:
		Log.info("[ConfigService][set_user_setting] Value unchanged for %s, skipping" % p_setting_name)
		return  # No change needed

	_unsaved_changes[p_setting_name] = p_value
	Log.info("[ConfigService][set_user_setting] User setting %s updated with unsaved changes" % p_setting_name)
	setting_changed.emit(p_setting_name, p_value)

	if p_save_immediately:
		Log.info("[ConfigService][set_user_setting] Saving user config immediately")
		save_user_config()


## Set an app setting (typically used by the application, not user)
func set_app_setting(p_setting_name: String, p_value, p_save_immediately: bool = false) -> void:
	Log.info("[ConfigService][set_app_setting] Setting app setting: %s = %s" % [p_setting_name, p_value])
	_app_config[p_setting_name] = p_value

	if p_save_immediately:
		Log.info("[ConfigService][set_app_setting] Saving app config immediately")
		_save_app_config()


## Get user configuration dictionary
func get_user_config() -> Dictionary:
	Log.info("[ConfigService][get_user_config] Getting user configuration dictionary")
	var config = _user_config.duplicate(true)
	# Apply unsaved changes
	for key in _unsaved_changes:
		if _is_user_setting(key):
			config[key] = _unsaved_changes[key]

	Log.info("[ConfigService][get_user_config] Returning user config with %d settings" % config.size())
	return config


## Get app configuration dictionary
func get_app_config() -> Dictionary:
	Log.info("[ConfigService][get_app_config] Getting app configuration dictionary")
	var config = _app_config.duplicate(true)
	Log.info("[ConfigService][get_app_config] Returning app config with %d settings" % config.size())
	return config


## Check if there are unsaved changes
func has_unsaved_changes() -> bool:
	var has_changes = not _unsaved_changes.is_empty()
	if has_changes:
		Log.info("[ConfigService][has_unsaved_changes] %d unsaved changes detected" % _unsaved_changes.size())
	return has_changes


## Discard unsaved changes
func discard_unsaved_changes() -> void:
	Log.info("[ConfigService][discard_unsaved_changes] Discarding %d unsaved changes" % _unsaved_changes.size())
	_unsaved_changes.clear()


## Reset user configuration to defaults
func reset_user_config_to_defaults(p_save_immediately: bool = true) -> void:
	Log.info("[ConfigService][reset_user_config_to_defaults] Resetting user config to defaults")
	_user_config = DEFAULT_USER_CONFIG.duplicate(true)
	_unsaved_changes.clear()

	if p_save_immediately:
		Log.info("[ConfigService][reset_user_config_to_defaults] Saving user config immediately after reset")
		save_user_config()

	Log.info("[ConfigService][reset_user_config_to_defaults] User config reset complete")


## Reset app configuration to defaults
func reset_app_config_to_defaults(p_save_immediately: bool = true) -> void:
	Log.info("[ConfigService][reset_app_config_to_defaults] Resetting app config to defaults")
	_app_config = DEFAULT_APP_CONFIG.duplicate(true)

	if p_save_immediately:
		Log.info("[ConfigService][reset_app_config_to_defaults] Saving app config immediately after reset")
		_save_app_config()

	Log.info("[ConfigService][reset_app_config_to_defaults] App config reset complete")


## Save only user configuration
func save_user_config() -> bool:
	Log.info("[ConfigService][save_user_config] Saving user configuration")

	# Apply unsaved user changes
	var changes_applied = 0
	for key in _unsaved_changes:
		if _is_user_setting(key):
			_user_config[key] = _unsaved_changes[key]
			changes_applied += 1

	Log.info("[ConfigService][save_user_config] Applied %d unsaved changes to user config" % changes_applied)

	# Remove applied changes
	var keys_to_remove = []
	for key in _unsaved_changes:
		if _is_user_setting(key):
			keys_to_remove.append(key)

	for key in keys_to_remove:
		_unsaved_changes.erase(key)

	var success = _save_user_config()
	if success:
		Log.info("[ConfigService][save_user_config] User configuration saved successfully")
	else:
		Log.error("[ConfigService][save_user_config] Failed to save user configuration")

	return success


## Export user configuration for backup
func export_user_config(p_export_path: String) -> bool:
	Log.info("[ConfigService][export_user_config] Exporting user config to: %s" % p_export_path)
	var export_data = get_user_config()
	var success = DataManager.save_json(p_export_path, export_data)

	if success:
		Log.info("[ConfigService][export_user_config] User config exported successfully")
	else:
		Log.error("[ConfigService][export_user_config] Failed to export user config")

	return success


## Import user configuration from backup
func import_user_config(p_import_path: String) -> bool:
	Log.info("[ConfigService][import_user_config] Importing user config from: %s" % p_import_path)

	if not FileAccess.file_exists(p_import_path):
		Log.error("[ConfigService][import_user_config] Import file does not exist: %s" % p_import_path)
		return false

	var imported_config = DataManager.load_json(p_import_path, {})
	if imported_config.is_empty():
		Log.error("[ConfigService][import_user_config] Failed to load import file or file is empty")
		return false

	Log.info("[ConfigService][import_user_config] Loaded %d settings from import file" % imported_config.size())
	_user_config = imported_config
	_unsaved_changes.clear()

	var success = save_user_config()
	if success:
		Log.info("[ConfigService][import_user_config] User config imported and saved successfully")
	else:
		Log.error("[ConfigService][import_user_config] Failed to save imported config")

	return success


## Get configuration summary for debugging
func get_config_summary() -> Dictionary:
	Log.info("[ConfigService][get_config_summary] Generating config summary")
	var summary = {
		"is_loaded": _is_loaded,
		"app_settings_count": _app_config.size(),
		"user_settings_count": _user_config.size(),
		"unsaved_changes_count": _unsaved_changes.size(),
		"unsaved_changes": _unsaved_changes.keys()
	}

	Log.info("[ConfigService][get_config_summary] Summary generated - loaded: %s, app: %d, user: %d, unsaved: %d" % [
		summary.is_loaded, summary.app_settings_count, summary.user_settings_count, summary.unsaved_changes_count
	])

	return summary


# Private methods

func _load_app_config() -> void:
	Log.info("[ConfigService][_load_app_config] Loading app configuration from: %s" % APP_CONFIG_PATH)
	_app_config = DataManager.load_json(APP_CONFIG_PATH, DEFAULT_APP_CONFIG)
	Log.info("[ConfigService][_load_app_config] App config loaded with %d settings" % _app_config.size())


func _load_user_config() -> void:
	Log.info("[ConfigService][_load_user_config] Loading user configuration from: %s" % USER_CONFIG_PATH)
	_user_config = DataManager.load_json(USER_CONFIG_PATH, DEFAULT_USER_CONFIG)
	Log.info("[ConfigService][_load_user_config] User config loaded with %d settings" % _user_config.size())


func _save_app_config() -> bool:
	Log.info("[ConfigService][_save_app_config] Saving app configuration to: %s" % APP_CONFIG_PATH)
	var success = DataManager.save_json(APP_CONFIG_PATH, _app_config)

	if success:
		Log.info("[ConfigService][_save_app_config] App configuration saved successfully")
	else:
		Log.error("[ConfigService][_save_app_config] Failed to save app configuration")

	return success


func _save_user_config() -> bool:
	Log.info("[ConfigService][_save_user_config] Saving user configuration to: %s" % USER_CONFIG_PATH)
	var success = DataManager.save_json(USER_CONFIG_PATH, _user_config)

	if success:
		Log.info("[ConfigService][_save_user_config] User configuration saved successfully")
	else:
		Log.error("[ConfigService][_save_user_config] Failed to save user configuration")

	return success


func _is_rser_setting(p_setting_name: String) -> bool:
	var is_user = DEFAULT_USER_CONFIG.has(p_setting_name) or not DEFAULT_APP_CONFIG.has(p_setting_name)
	Log.info("[ConfigService][_is_user_setting] Setting %s is user setting: %s" % [p_setting_name, is_user])
	return is_user
