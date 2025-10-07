class_name DataManager
extends RefCounted

## Unified data management service that handles file operations and path management
## Replaces the functionality of JSONManager and FilePaths autoloads


# Base directories
const USER_DATA_DIR = "user://data/"
const CONFIG_DIR = "user://data/config/"
const PROFILES_DIR = "user://data/profiles/"
const STATS_DIR = "user://data/statistics/"
const CACHE_DIR = "user://cache/"
const BACKUPS_DIR = "user://cache/backups/"

# Specific file paths
const APP_CONFIG = "user://data/config/app_config.json"
const UI_CONFIG = "user://data/config/ui_config.json"
const DEFAULT_PROFILE = "user://data/profiles/default_profile.json"
const DAILY_STATS = "user://data/statistics/daily_stats.json"
const OVERALL_STATS = "user://data/statistics/overall_stats.json"

# Read-only default data (shipped with game)
const DEFAULT_LESSONS = "res://assets/data/default_lessons.json"
const DEFAULT_CONFIG = "res://assets/data/default_config.json"
const KEYBOARD_LAYOUTS = "res://assets/data/keyboard_layouts.json"


## Save JSON data to file with automatic directory creation
static func save_json(p_path: String, p_data: Dictionary, p_pretty: bool = true) -> bool:
	Log.info("[DataManager][save_json] Saving JSON data to: %s" % p_path)

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
	Log.info("[DataManager][save_json] JSON data saved successfully to: %s" % p_path)
	return true


## Load JSON data from file with fallback to default
static func load_json(p_path: String, p_default_data: Dictionary = {}) -> Dictionary:
	Log.info("[DataManager][load_json] Loading JSON data from: %s" % p_path)

	if not FileAccess.file_exists(p_path):
		Log.info("[DataManager][load_json] File does not exist, returning default data: %s" % p_path)
		return p_default_data.duplicate(true)

	var file = FileAccess.open(p_path, FileAccess.READ)
	if file == null:
		Log.error("[DataManager][load_json] Error opening file for reading: %s" % p_path)
		return p_default_data.duplicate(true)

	var json_string = file.get_as_text()
	file.close()

	if json_string.is_empty():
		Log.error("[DataManager][load_json] File is empty: %s" % p_path)
		return p_default_data.duplicate(true)

	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		Log.error("[DataManager][load_json] JSON parse error in %s: %s" % [p_path, json.get_error_message()])
		return p_default_data.duplicate(true)

	Log.info("[DataManager][load_json] JSON data loaded successfully from: %s" % p_path)
	return json.data


## Ensure all necessary directories exist
static func ensure_directories() -> void:
	Log.info("[DataManager][ensure_directories] Ensuring all necessary directories exist")

	var directories = [
		USER_DATA_DIR, CONFIG_DIR, PROFILES_DIR,
		STATS_DIR, CACHE_DIR, BACKUPS_DIR
	]

	var created_count = 0
	for dir_path in directories:
		if _create_directory_if_not_exists(dir_path):
			created_count += 1

	Log.info("[DataManager][ensure_directories] Directory check complete, %d directories processed, %d created" % [directories.size(), created_count])


## Create backup of a file
static func create_backup(p_original_path: String) -> bool:
	Log.info("[DataManager][create_backup] Creating backup of: %s" % p_original_path)

	if not FileAccess.file_exists(p_original_path):
		Log.error("[DataManager][create_backup] Original file does not exist: %s" % p_original_path)
		return false

	_create_directory_if_not_exists(BACKUPS_DIR)
	var backup_path = get_backup_path(p_original_path)

	var success = DirAccess.copy_absolute(p_original_path, backup_path) == OK
	if success:
		Log.info("[DataManager][create_backup] Backup created successfully: %s" % backup_path)
	else:
		Log.error("[DataManager][create_backup] Failed to create backup: %s" % backup_path)

	return success


## Get backup path for a file with timestamp
static func get_backup_path(p_original_path: String) -> String:
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var filename = p_original_path.get_file()
	var backup_path = BACKUPS_DIR.path_join("%s.%s.backup" % [filename, timestamp])
	Log.info("[DataManager][get_backup_path] Generated backup path: %s" % backup_path)
	return backup_path


## Get user-specific profile path
static func get_user_profile_path(p_username: String) -> String:
	var profile_path = PROFILES_DIR.path_join("%s_profile.json" % p_username.to_lower())
	Log.info("[DataManager][get_user_profile_path] Generated profile path for %s: %s" % [p_username, profile_path])
	return profile_path


## Get temporary file path
static func get_temp_path(p_prefix: String = "temp") -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_id = randi() % 10000
	var temp_path = CACHE_DIR.path_join("%s_%d_%d.tmp" % [p_prefix, timestamp, random_id])
	Log.info("[DataManager][get_temp_path] Generated temp path: %s" % temp_path)
	return temp_path


## Check if path is within user data directory (security check)
static func is_valid_user_data_path(p_path: String) -> bool:
	var is_valid = p_path.begins_with("user://data/") or p_path.begins_with("user://cache/")
	Log.info("[DataManager][is_valid_user_data_path] Path validation for %s: %s" % [p_path, is_valid])
	return is_valid


## List files in directory with extension filter
static func list_files(p_directory: String, p_extension_filter: String = "json") -> Array:
	Log.info("[DataManager][list_files] Listing files in %s with extension: %s" % [p_directory, p_extension_filter])

	var files = []
	var dir = DirAccess.open(p_directory)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension() == p_extension_filter:
				files.append(p_directory.path_join(file_name))
			file_name = dir.get_next()
		Log.info("[DataManager][list_files] Found %d files in directory" % files.size())
	else:
		Log.error("[DataManager][list_files] Failed to open directory: %s" % p_directory)

	return files


## Validate JSON data against required keys
static func validate_json_schema(p_data: Dictionary, p_required_keys: Array) -> bool:
	Log.info("[DataManager][validate_json_schema] Validating JSON schema with %d required keys" % p_required_keys.size())

	for key in p_required_keys:
		if not p_data.has(key):
			Log.error("[DataManager][validate_json_schema] Missing required key in JSON data: %s" % str(key))
			return false

	Log.info("[DataManager][validate_json_schema] JSON schema validation passed")
	return true


## Deep merge two dictionaries
static func merge_dictionaries(p_target: Dictionary, p_source: Dictionary) -> Dictionary:
	Log.info("[DataManager][merge_dictionaries] Merging dictionaries - target: %d keys, source: %d keys" % [p_target.size(), p_source.size()])

	var result = p_target.duplicate(true)

	for key in p_source:
		if result.has(key) and result[key] is Dictionary and p_source[key] is Dictionary:
			result[key] = merge_dictionaries(result[key], p_source[key])
		else:
			result[key] = p_source[key]

	Log.info("[DataManager][merge_dictionaries] Merge complete - result: %d keys" % result.size())
	return result


## Copy file with backup option
static func copy_file(p_source: String, p_destination: String, p_create_backup: bool = false) -> bool:
	Log.info("[DataManager][copy_file] Copying file from %s to %s (backup: %s)" % [p_source, p_destination, p_create_backup])

	if not FileAccess.file_exists(p_source):
		Log.error("[DataManager][copy_file] Source file does not exist: %s" % p_source)
		return false

	if p_create_backup and FileAccess.file_exists(p_destination):
		Log.info("[DataManager][copy_file] Creating backup of existing destination file")
		create_backup(p_destination)

	if not _ensure_directory_for_file(p_destination):
		Log.error("[DataManager][copy_file] Failed to ensure directory for destination file")
		return false

	var success = DirAccess.copy_absolute(p_source, p_destination) == OK
	if success:
		Log.info("[DataManager][copy_file] File copied successfully")
	else:
		Log.error("[DataManager][copy_file] Failed to copy file")

	return success


## Delete file safely with optional backup
static func delete_file(p_path: String, p_create_backup: bool = true) -> bool:
	Log.info("[DataManager][delete_file] Deleting file: %s (backup: %s)" % [p_path, p_create_backup])

	if not FileAccess.file_exists(p_path):
		Log.info("[DataManager][delete_file] File doesn't exist, considering it deleted: %s" % p_path)
		return true  # File doesn't exist, consider it deleted

	if p_create_backup:
		Log.info("[DataManager][delete_file] Creating backup before deletion")
		create_backup(p_path)

	var success = DirAccess.remove_absolute(p_path) == OK
	if success:
		Log.info("[DataManager][delete_file] File deleted successfully")
	else:
		Log.error("[DataManager][delete_file] Failed to delete file")

	return success


# Private helper methods

static func _ensure_directory_for_file(p_file_path: String) -> bool:
	var dir_path = p_file_path.get_base_dir()
	return _create_directory_if_not_exists(dir_path)


static func _create_directory_if_not_exists(p_dir_path: String) -> bool:
	if not DirAccess.dir_exists_absolute(p_dir_path):
		Log.info("[DataManager][_create_directory_if_not_exists] Creating directory: %s" % p_dir_path)
		var error = DirAccess.make_dir_recursive_absolute(p_dir_path)
		if error != OK:
			Log.error("[DataManager][_create_directory_if_not_exists] Failed to create directory: %s" % p_dir_path)
			return false
		Log.info("[DataManager][_create_directory_if_not_exists] Directory created successfully: %s" % p_dir_path)
	return true
