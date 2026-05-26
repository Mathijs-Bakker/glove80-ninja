extends Node

signal config_loaded
signal config_saved
signal setting_changed(p_setting_name: String, p_new_value)

var _config_path: String
var _user_config: Dictionary = {}

# Internal state
var _app_config: Dictionary = {"app_version": "0.1.0", "theme": "dark", "language": "en"}
var _unsaved_changes: Dictionary = {}
var _is_loaded: bool = false
var _is_initialized: bool = false


func _ready() -> void:
	initialize()


func initialize() -> void:
	if _is_initialized:
		return

	if not UserService.profile_loaded.is_connected(_load_config):
		UserService.profile_loaded.connect(_load_config)

	_is_initialized = true


func _create_config_path(p_user_id: int) -> String:
	return User.USER_PROFILE_PREPEND_PATH + str(p_user_id) + "/" + User.FILE_SETTINGS


func _load_config() -> void:
	var user_data = UserService.get_user_dir_path()
	_config_path = _create_config_path(user_data.get("user_id", 0))
	Log.info("[|ConfigService][load_config] Loading configuration from: %s" % _config_path)

	_user_config = DataManager.load_json(_config_path, User.DEFAULT_USER_SETTINGS)
	for setting_name in User.DEFAULT_USER_SETTINGS:
		if not _user_config.has(setting_name):
			_user_config[setting_name] = User.DEFAULT_USER_SETTINGS[setting_name]
	_unsaved_changes.clear()
	_is_loaded = true
	config_loaded.emit()


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


func set_user_setting(p_setting_name: String, p_new_value) -> void:
	if get_setting(p_setting_name) == p_new_value:
		return

	_unsaved_changes[p_setting_name] = p_new_value
	setting_changed.emit(p_setting_name, p_new_value)


func has_unsaved_changes() -> bool:
	return not _unsaved_changes.is_empty()


func save_user_config() -> bool:
	if _config_path.is_empty():
		return false

	for setting_name in _unsaved_changes:
		_user_config[setting_name] = _unsaved_changes[setting_name]

	var success = DataManager.save_json(_config_path, _user_config)
	if success:
		_unsaved_changes.clear()
		config_saved.emit()

	return success


func save_all_configs() -> bool:
	return save_user_config()


func reset_user_config_to_defaults(p_save_immediately: bool = false) -> void:
	_user_config = User.DEFAULT_USER_SETTINGS.duplicate(true)
	_unsaved_changes.clear()

	if p_save_immediately:
		DataManager.save_json(_config_path, _user_config)
		config_saved.emit()

	config_loaded.emit()
