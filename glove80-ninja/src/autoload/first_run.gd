class_name FirstRunSetup
extends Node

const DEFAULT_USER_ID: String = "0"


func run_setup_async() -> void:
	Log.info("[FirstRunSetup][run_setup_async] Starting first run setup.")
	_create_directory(User.DATA_PATH)
	DataManager.save_json(User.USERS_PATH, User.INIT_USERS_DATA)

	# Create default user in default path: 'user://data/user_0/'
	_create_directory(User.USER_PROFILE_PREPEND_PATH + DEFAULT_USER_ID)

	var user_profile = User.DEFAULT_PROFILE
	user_profile.set(User.PROFILE.CREATED_DATE, Time.get_datetime_string_from_system())
	_save_data(User.FILE_PROFILE, user_profile)

	_save_data(User.FILE_SETTINGS, User.DEFAULT_USER_SETTINGS)
	_save_data(User.FILE_STATS, User.DEFAULT_STATS)


func _create_directory(p_path: String) -> bool:
	if not DirAccess.dir_exists_absolute(p_path):
		Log.info("[FirstRunSetup][_create_directory] Creating directory: %s" % p_path)
		var error = DirAccess.make_dir_recursive_absolute(p_path)
		if error != OK:
			Log.error("[FirstRunSetup][create_directory] Failed to create directory: %s" % p_path)
			return false
		Log.info("[FirstRunSetup][_create_directory] Directory created s" % p_path)
		return true
	return false


func _save_data(p_file_name, p_data) -> void:
	Log.info("[FirstRunSetup][_save_data] Create a default user profile.")

	var success = DataManager.save_json(
		User.USER_PROFILE_PREPEND_PATH + DEFAULT_USER_ID + "/" + p_file_name, p_data
	)
	if success:
		Log.info("[FirstRunSetup][_save_data] %s saved." % p_data)
	else:
		Log.error("[FirstRunSetup][_save_data] Failed to save %s." % p_data)
