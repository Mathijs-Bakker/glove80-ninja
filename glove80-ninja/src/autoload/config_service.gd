extends Control

signal config_loaded
signal config_saved
signal setting_changed(p_setting_name: String, p_new_value)

var _config_path: String
var _user_config: UserConfig

# Internal state
var _app_config: Dictionary = {}
var _unsaved_changes: Dictionary = {}
var _is_loaded: bool = false


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

	var _dict = DataManager.load_json(_config_path, User.DEFAULT_USER_SETTINGS)

	# _is_loaded = true
	config_loaded.emit()


## Get a setting value (checks user config first, then app config)
func get_setting(p_setting_name: String, p_default_value = null):
	Log.info("[ConfigService][get_setting] Getting setting: %s" % p_setting_name)

	# Check unsaved changes first
	if _unsaved_changes.has(p_setting_name):
		Log.info("[ConfigService][get_setting] Found unsaved value for %s" % p_setting_name)
		return _unsaved_changes[p_setting_name]

	# Check user config
	# if _user_config.get_stats().has(p_setting_name):
	# 	Log.info("[ConfigService][get_setting] Found user config value for %s" % p_setting_name)
	# 	return _user_config[p_setting_name]

	# Check app config
	if _app_config.has(p_setting_name):
		Log.info("[ConfigService][get_setting] Found app config value for %s" % p_setting_name)
		return _app_config[p_setting_name]

	# Check defaults
	# if DEFAULT_USER_CONFIG.has(p_setting_name):
	# 	Log.info("[ConfigService][get_setting] Using user default for %s" % p_setting_name)
	# 	return DEFAULT_USER_CONFIG[p_setting_name]

	# if DEFAULT_APP_CONFIG.has(p_setting_name):
	# 	Log.info("[ConfigService][get_setting] Using app default for %s" % p_setting_name)
	# 	return DEFAULT_APP_CONFIG[p_setting_name]

	Log.info(
		"[ConfigService][get_setting] No value found for %s, returning default" % p_setting_name
	)
	return p_default_value


class UserConfig:
	var uc = User.APP_CONFIG
	var us = User.STATS

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
		all_time_time_typed = p_stats.get(us.ALL_TIME_TIME_TYPED, 0.0)
		all_time_best_wpm = p_stats.get(us.ALL_TIME_BEST_WPM, 0.0)
		all_time_average_wpm = p_stats.get(us.ALL_TIME_AVERAGE_WPM, 0.0)
		all_time_best_accuracy = p_stats.get(us.ALL_TIME_BEST_ACCURACY, 0.0)
		all_time_average_accuracy = p_stats.get(us.ALL_TIME_AVERAGE_ACCURACY, 0.0)
		all_time_sessions_completed = p_stats.get(us.ALL_TIME_SESSIONS_COMPLETED, 0.0)
		today_time_typed = p_stats.get(us.TODAY_TIME_TYPED, 0.0)
		today_best_wpm = p_stats.get(us.TODAY_BEST_WPM, 0.0)
		today_average_wpm = p_stats.get(us.TODAY_AVERAGE_WPM, 0.0)
		today_best_accuracy = p_stats.get(us.TODAY_BEST_ACCURACY, 0.0)
		today_average_accuracy = p_stats.get(us.TODAY_AVERAGE_ACCURACY, 0.0)
		today_sessions_completed = p_stats.get(us.TODAY_SESSIONS_COMPLETED, 0.0)
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
			us.STATS.ALL_TIME_TIME_TYPED: all_time_time_typed,
			us.ALL_TIME_BEST_WPM: all_time_best_wpm,
			us.ALL_TIME_AVERAGE_WPM: all_time_average_wpm,
			us.ALL_TIME_BEST_ACCURACY: all_time_best_accuracy,
			us.ALL_TIME_AVERAGE_ACCURACY: all_time_average_accuracy,
			us.ALL_TIME_SESSIONS_COMPLETED: all_time_sessions_completed,
			us.TODAY_TIME_TYPED: today_time_typed,
			us.TODAY_BEST_WPM: today_best_wpm,
			us.TODAY_AVERAGE_WPM: today_average_wpm,
			us.TODAY_BEST_ACCURACY: today_best_accuracy,
			us.TODAY_AVERAGE_ACCURACY: today_average_accuracy,
			us.TODAY_SESSIONS_COMPLETED: today_sessions_completed,
		}
