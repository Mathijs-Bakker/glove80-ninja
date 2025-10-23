extends Control

## Handles all application and user settings with proper separation of concerns

signal config_loaded
signal config_saved
signal setting_changed(p_setting_name: String, p_new_value)

var _config_path: String
var _user_config: UserConfig

# Internal state
var _app_config: Dictionary = {}
var _unsaved_changes: Dictionary = {}
var _is_loaded: bool = false

# func _load_stats() -> void:
# 	var user_data = UserService.get_user_dir_path()
# 	_stats_path = _create_stats_path(user_data.get("user_id"))
# 	Log.info("[StatsService][load_stats] Loading user stats from: %s" % _stats_path)
# 	_stats = DataManager.load_json(_stats_path, User.DEFAULT_STATS)

# 	if _stats[User.STATS.ALL_TIME_TIME_TYPED] == 0.0:
# 		Log.info("[StatsService][load_profile] Set stats for new user")
# 		# save_stats()
# 		DataManager.save_json(_stats_path, User.DEFAULT_STATS)


func _ready() -> void:
	# load_configs()
	UserService.profile_loaded.connect(_load_config)
	_user_config = UserConfig.new()


func _create_stats_path(p_user_id) -> String:
	var prepend_path = "user://data/user_"
	return prepend_path + str(p_user_id) + "/config.json"


func _load_config() -> void:
	var user_data = UserService.get_user_dir_path()
	_config_path = _create_stats_path(user_data.get("user_id"))
	Log.info("[|ConfigService][load_config] Loading configuration from: %s" % _config_path)

	var _dict = DataManager.load_json(_config_path, User.DEFAULT_USER_CONFIG)

	# _is_loaded = true
	# config_loaded.emit()


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

	(
		Log
		. error(
			(
				"[ConfigService][save_all_configs] Failed to save configurations - app_saved: %s, user_saved: %s"
				% [app_saved, user_saved]
			)
		)
	)
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

	Log.info(
		"[ConfigService][get_setting] No value found for %s, returning default" % p_setting_name
	)
	return p_default_value


# func set_user_setting(p_setting_name: String, p_value, p_save_immediately: bool = false) -> void:
# 	Log.info(
# 		(
# 			"[ConfigService][set_user_setting] Setting user setting: %s = %s"
# 			% [p_setting_name, p_value]
# 		)
# 	)
# 	var current_value = get_setting(p_setting_name)

# 	if current_value == p_value:
# 		Log.info(
# 			"[ConfigService][set_user_setting] Value unchanged for %s, skipping" % p_setting_name
# 		)
# 		return

# 	_unsaved_changes[p_setting_name] = p_value
# 	Log.info(
# 		(
# 			"[ConfigService][set_user_setting] User setting %s updated with unsaved changes"
# 			% p_setting_name
# 		)
# 	)
# 	setting_changed.emit(p_setting_name, p_value)

# 	if p_save_immediately:
# 		Log.info("[ConfigService][set_user_setting] Saving user config immediately")
# 		save_user_config()


# ## Set an app setting (typically used by the application, not user)
func set_app_setting(p_setting_name: String, p_value, p_save_immediately: bool = false) -> void:
	Log.info(
		"[ConfigService][set_app_setting] Setting app setting: %s = %s" % [p_setting_name, p_value]
	)
	_app_config[p_setting_name] = p_value

	if p_save_immediately:
		Log.info("[ConfigService][set_app_setting] Saving app config immediately")
		_save_app_config()


# func get_user_config() -> Dictionary:
# 	Log.info("[ConfigService][get_user_config] Getting user configuration dictionary")
# 	var config = _user_config.duplicate(true)

# 	for key in _unsaved_changes:
# 		if _is_user_setting(key):
# 			config[key] = _unsaved_changes[key]

# 	Log.info(
# 		"[ConfigService][get_user_config] Returning user config with %d settings" % config.size()
# 	)
# 	return config

# func get_app_config() -> Dictionary:
# 	Log.info("[ConfigService][get_app_config] Getting app configuration dictionary")
# 	var config = _app_config.duplicate(true)
# 	Log.info(
# 		"[ConfigService][get_app_config] Returning app config with %d settings" % config.size()
# 	)
# 	return config

# func has_unsaved_changes() -> bool:
# 	var has_changes = not _unsaved_changes.is_empty()
# 	if has_changes:
# 		Log.info(
# 			(
# 				"[ConfigService][has_unsaved_changes] %d unsaved changes detected"
# 				% _unsaved_changes.size()
# 			)
# 		)
# 	return has_changes

# func discard_unsaved_changes() -> void:
# 	Log.info(
# 		(
# 			"[ConfigService][discard_unsaved_changes] Discarding %d unsaved changes"
# 			% _unsaved_changes.size()
# 		)
# 	)
# 	_unsaved_changes.clear()

# func reset_user_config_to_defaults(p_save_immediately: bool = true) -> void:
# 	Log.info("[ConfigService][reset_user_config_to_defaults] Resetting user config to defaults")
# 	_user_config = DEFAULT_USER_CONFIG.duplicate(true)
# 	_unsaved_changes.clear()

# 	if p_save_immediately:
# 		(
# 			Log
# 			. info(
# 				"[ConfigService][reset_user_config_to_defaults] Saving user config immediately after reset"
# 			)
# 		)
# 		save_user_config()

# 	Log.info("[ConfigService][reset_user_config_to_defaults] User config reset complete")

# func reset_app_config_to_defaults(p_save_immediately: bool = true) -> void:
# 	Log.info("[ConfigService][reset_app_config_to_defaults] Resetting app config to defaults")
# 	_app_config = DEFAULT_APP_CONFIG.duplicate(true)

# 	if p_save_immediately:
# 		(
# 			Log
# 			. info(
# 				"[ConfigService][reset_app_config_to_defaults] Saving app config immediately after reset"
# 			)
# 		)
# 		_save_app_config()

# 	Log.info("[ConfigService][reset_app_config_to_defaults] App config reset complete")


func save_user_config() -> bool:
	Log.info("[ConfigService][save_user_config] Saving user configuration")

	# Apply unsaved changes
	var changes_applied = 0
	for key in _unsaved_changes:
		if _is_user_setting(key):
			_user_config[key] = _unsaved_changes[key]
			changes_applied += 1

	Log.info(
		(
			"[ConfigService][save_user_config] Applied %d unsaved changes to user config"
			% changes_applied
		)
	)

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


# func export_user_config(p_export_path: String) -> bool:
# 	Log.info("[ConfigService][export_user_config] Exporting user config to: %s" % p_export_path)
# 	var export_data = get_user_config()
# 	var success = DataManager.save_json(p_export_path, export_data)

# 	if success:
# 		Log.info("[ConfigService][export_user_config] User config exported successfully")
# 	else:
# 		Log.error("[ConfigService][export_user_config] Failed to export user config")

# 	return success

# func import_user_config(p_import_path: String) -> bool:
# 	Log.info("[ConfigService][import_user_config] Importing user config from: %s" % p_import_path)

# 	if not FileAccess.file_exists(p_import_path):
# 		Log.error(
# 			"[ConfigService][import_user_config] Import file does not exist: %s" % p_import_path
# 		)
# 		return false

# 	var imported_config = DataManager.load_json(p_import_path, {})
# 	if imported_config.is_empty():
# 		Log.error("[ConfigService][import_user_config] Failed to load import file or file is empty")
# 		return false

# 	Log.info(
# 		(
# 			"[ConfigService][import_user_config] Loaded %d settings from import file"
# 			% imported_config.size()
# 		)
# 	)
# 	_user_config = imported_config
# 	_unsaved_changes.clear()

# 	var success = save_user_config()
# 	if success:
# 		Log.info("[ConfigService][import_user_config] User config imported and saved successfully")
# 	else:
# 		Log.error("[ConfigService][import_user_config] Failed to save imported config")

# 	return success

# ## Get configuration summary for debugging
# func get_config_summary() -> Dictionary:
# 	Log.info("[ConfigService][get_config_summary] Generating config summary")
# 	var summary = {
# 		"is_loaded": _is_loaded,
# 		"app_settings_count": _app_config.size(),
# 		"user_settings_count": _user_config.size(),
# 		"unsaved_changes_count": _unsaved_changes.size(),
# 		"unsaved_changes": _unsaved_changes.keys()
# 	}

# 	(
# 		Log
# 		. info(
# 			(
# 				"[ConfigService][get_config_summary] Summary generated - loaded: %s, app: %d, user: %d, unsaved: %d"
# 				% [
# 					summary.is_loaded,
# 					summary.app_settings_count,
# 					summary.user_settings_count,
# 					summary.unsaved_changes_count
# 				]
# 			)
# 		)
# 	)

# 	return summary

# Private methods


func _save_app_config() -> bool:
	Log.info("[ConfigService][_save_app_config] Saving app configuration to: %s" % APP_CONFIG_PATH)
	var success = DataManager.save_json(APP_CONFIG_PATH, _app_config)

	if success:
		Log.info("[ConfigService][_save_app_config] App configuration saved successfully")
	else:
		Log.error("[ConfigService][_save_app_config] Failed to save app configuration")

	return success


func _save_user_config() -> bool:
	Log.info(
		"[ConfigService][_save_user_config] Saving user configuration to: %s" % USER_CONFIG_PATH
	)
	var success = DataManager.save_json(USER_CONFIG_PATH, _user_config)

	if success:
		Log.info("[ConfigService][_save_user_config] User configuration saved successfully")
	else:
		Log.error("[ConfigService][_save_user_config] Failed to save user configuration")

	return success


func _is_user_setting(p_setting_name: String) -> bool:
	var is_user = (
		DEFAULT_USER_CONFIG.has(p_setting_name) or not DEFAULT_APP_CONFIG.has(p_setting_name)
	)
	Log.info(
		(
			"[ConfigService][_is_user_setting] Setting %s is user setting: %s"
			% [p_setting_name, is_user]
		)
	)
	return is_user


class UserConfig:
	var uc = User.APP_CONFIG
	var us = User.LESSONS_SETTING

	var all_time_time_typed: float
	var all_time_best_wpm: float
	var all_time_average_wpm: float
	var all_time_best_accuracy: float
	var all_time_average_accuracy: float
	var all_time_sessions_completed: float

	var today_time_typed: float
	var today_best_wpm: float
	var today_average_wpm: float
	var today_best_accuracy: float
	var today_average_accuracy: float
	var today_sessions_completed: float

	func from_dict(p_stats: Dictionary) -> void:
		all_time_time_typed = p_stats.get(User.STATS.ALL_TIME_TIME_TYPED, 0.0)
		all_time_best_wpm = p_stats.get(User.STATS.ALL_TIME_BEST_WPM, 0.0)
		all_time_average_wpm = p_stats.get(User.STATS.ALL_TIME_AVERAGE_WPM, 0.0)
		all_time_best_accuracy = p_stats.get(User.STATS.ALL_TIME_BEST_ACCURACY, 0.0)
		all_time_average_accuracy = p_stats.get(User.STATS.ALL_TIME_AVERAGE_ACCURACY, 0.0)
		all_time_sessions_completed = p_stats.get(User.STATS.ALL_TIME_SESSIONS_COMPLETED, 0.0)
		today_time_typed = p_stats.get(User.STATS.TODAY_TIME_TYPED, 0.0)
		today_best_wpm = p_stats.get(User.STATS.TODAY_BEST_WPM, 0.0)
		today_average_wpm = p_stats.get(User.STATS.TODAY_AVERAGE_WPM, 0.0)
		today_best_accuracy = p_stats.get(User.STATS.TODAY_BEST_ACCURACY, 0.0)
		today_average_accuracy = p_stats.get(User.STATS.TODAY_AVERAGE_ACCURACY, 0.0)
		today_sessions_completed = p_stats.get(User.STATS.TODAY_SESSIONS_COMPLETED, 0.0)
		Log.info("[StatsService.UserStats][from_dict] Stats loaded")

	func to_dict(p_stats: Dictionary) -> void:
		Log.info("[StatsService.ProfileStats][to_dict] Exporting statistics")
		p_stats[us.ALL_TIME_TIME_TYPED] = all_time_time_typed
		p_stats[us.ALL_TIME_BEST_WPM] = all_time_best_wpm
		p_stats[us.ALL_TIME_AVERAGE_WPM] = all_time_average_wpm
		p_stats[us.ALL_TIME_BEST_ACCURACY] = all_time_best_accuracy
		p_stats[us.ALL_TIME_AVERAGE_ACCURACY] = all_time_average_accuracy
		p_stats[us.ALL_TIME_SESSIONS_COMPLETED] = all_time_sessions_completed
		p_stats[us.TODAY_TIME_TYPED] = today_time_typed
		p_stats[us.TODAY_BEST_WPM] = today_best_wpm
		p_stats[us.TODAY_AVERAGE_WPM] = today_average_wpm
		p_stats[us.TODAY_BEST_ACCURACY] = today_best_accuracy
		p_stats[us.TODAY_AVERAGE_ACCURACY] = today_average_accuracy
		p_stats[us.TODAY_SESSIONS_COMPLETED] = today_sessions_completed

	func get_stats() -> Dictionary:
		return {
			User.STATS.ALL_TIME_TIME_TYPED: all_time_time_typed,
			User.STATS.ALL_TIME_BEST_WPM: all_time_best_wpm,
			User.STATS.ALL_TIME_AVERAGE_WPM: all_time_average_wpm,
			User.STATS.ALL_TIME_BEST_ACCURACY: all_time_best_accuracy,
			User.STATS.ALL_TIME_AVERAGE_ACCURACY: all_time_average_accuracy,
			User.STATS.ALL_TIME_SESSIONS_COMPLETED: all_time_sessions_completed,
			User.STATS.TODAY_TIME_TYPED: today_time_typed,
			User.STATS.TODAY_BEST_WPM: today_best_wpm,
			User.STATS.TODAY_AVERAGE_WPM: today_average_wpm,
			User.STATS.TODAY_BEST_ACCURACY: today_best_accuracy,
			User.STATS.TODAY_AVERAGE_ACCURACY: today_average_accuracy,
			User.STATS.TODAY_SESSIONS_COMPLETED: today_sessions_completed,
		}
