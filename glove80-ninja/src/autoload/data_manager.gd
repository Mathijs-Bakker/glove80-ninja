extends Control

## Unified data management service that handles file operations and path management

# Specific file paths
const APP_CONFIG = "user://data/config/app_config.json"
const UI_CONFIG = "user://data/config/ui_config.json"
const DEFAULT_PROFILE = "user://data/profiles/default_profile.json"
const DAILY_STATS = "user://data/statistics/daily_stats.json"
const OVERALL_STATS = "user://data/statistics/overall_stats.json"

# # Read-only default data (shipped with game)
# const DEFAULT_LESSONS = "res://assets/data/default_lessons.json"
const DEFAULT_CONFIG = "res://assets/data/default_config.json"
# const KEYBOARD_LAYOUTS = "res://assets/data/keyboard_layouts.json"


func save_json(p_path: String, p_data: Dictionary, p_pretty: bool = true) -> bool:
	Log.info("[DataManager][save_json] Preparing to save JSON data to: %s" % p_path)

	if not _ensure_directory_for_file(p_path):
		Log.error("[DataManager][save_json] Failed to ensure directory for file: %s" % p_path)
		return false

	var file = FileAccess.open(p_path, FileAccess.WRITE)
	if file == null:
		Log.error("[DataManager][save_json] Error opening file for writing: %s" % p_path)
		return false

	var indent = "\t" if p_pretty else ""
	var json_string = JSON.stringify(p_data, indent)

	if json_string.is_empty():
		Log.error("[DataManager][save_json] Failed to stringify JSON data")
		file.close()
		return false

	file.store_string(json_string)
	file.close()
	Log.info("[DataManager][save_json] JSON data saved to: %s" % p_path)
	return true


func load_json(p_path: String, p_default_data: Dictionary = {}) -> Dictionary:
	Log.info("[DataManager][load_json] Loading JSON data from: %s" % p_path)

	if not FileAccess.file_exists(p_path):
		Log.info(
			(
				"[DataManager][load_json] File does not exist, returning default data: %s"
				% p_default_data
			)
		)
		return p_default_data.duplicate(true)

	var file = FileAccess.open(p_path, FileAccess.READ)
	if file == null:
		(
			Log
			. error(
				(
					"[DataManager][load_json] Error opening file for reading: %s, falling back to default"
					% p_path
				)
			)
		)
		return p_default_data.duplicate(true)

	var json_string = file.get_as_text()
	file.close()

	if json_string.is_empty():
		Log.error("[DataManager][load_json] File is empty: %s" % p_path)
		return p_default_data.duplicate(true)

	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		Log.error(
			(
				"[DataManager][load_json] JSON parse error in %s: %s"
				% [p_path, json.get_error_message()]
			)
		)
		return p_default_data.duplicate(true)

	Log.info("[DataManager][load_json] JSON data loaded from: %s" % p_path)
	return json.data


func ensure_directories_exist() -> void:
	Log.info("[DataManager][ensure_directories_exist] Ensuring all necessary directories exist")

	# var directories = [DATA_DIR, CONFIG_DIR, PROFILES_DIR, STATS_DIR, CACHE_DIR, BACKUPS_DIR]
	var directories = [User.DATA_DIR]

	var created_count = 0
	for dir_path in directories:
		if _create_directory_if_not_exists(dir_path):
			created_count += 1

	(
		Log
		. info(
			(
				"[DataManager][ensure_directories_exist] Directory check complete, %d directories processed, %d created"
				% [directories.size(), created_count]
			)
		)
	)


func _ensure_directory_for_file(p_file_path: String) -> bool:
	var dir_path = p_file_path.get_base_dir()
	_create_directory_if_not_exists(dir_path)

	return true


func _create_directory_if_not_exists(p_dir_path: String) -> bool:
	if not DirAccess.dir_exists_absolute(p_dir_path):
		Log.info(
			"[DataManager][_create_directory_if_not_exists] Creating directory: %s" % p_dir_path
		)
		var error = DirAccess.make_dir_recursive_absolute(p_dir_path)
		if error != OK:
			Log.error(
				(
					"[DataManager][_create_directory_if_not_exists] Failed to create directory: %s"
					% p_dir_path
				)
			)
			return false
		Log.info("[DataManager][_create_directory_if_not_exists] Directory created s" % p_dir_path)
		return true
	return false
