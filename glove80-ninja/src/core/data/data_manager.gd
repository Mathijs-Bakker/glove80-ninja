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
	if not _ensure_directory_for_file(p_path):
		return false

	var file = FileAccess.open(p_path, FileAccess.WRITE)
	if file == null:
		push_error("Error opening file for writing: " + p_path)
		return false

	var indent = "\t" if p_pretty else ""
	var json_string = JSON.stringify(p_data, indent)

	if json_string.is_empty():
		push_error("Failed to stringify JSON data")
		file.close()
		return false

	file.store_string(json_string)
	file.close()
	return true


## Load JSON data from file with fallback to default
static func load_json(p_path: String, p_default_data: Dictionary = {}) -> Dictionary:
	if not FileAccess.file_exists(p_path):
		return p_default_data.duplicate(true)

	var file = FileAccess.open(p_path, FileAccess.READ)
	if file == null:
		push_error("Error opening file for reading: " + p_path)
		return p_default_data.duplicate(true)

	var json_string = file.get_as_text()
	file.close()

	if json_string.is_empty():
		return p_default_data.duplicate(true)

	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		push_error("JSON parse error: " + json.get_error_message())
		return p_default_data.duplicate(true)

	return json.data


## Ensure all necessary directories exist
static func ensure_directories() -> void:
	var directories = [
		USER_DATA_DIR, CONFIG_DIR, PROFILES_DIR,
		STATS_DIR, CACHE_DIR, BACKUPS_DIR
	]

	for dir_path in directories:
		_create_directory_if_not_exists(dir_path)


## Create backup of a file
static func create_backup(p_original_path: String) -> bool:
	if not FileAccess.file_exists(p_original_path):
		return false

	_create_directory_if_not_exists(BACKUPS_DIR)
	var backup_path = get_backup_path(p_original_path)

	return DirAccess.copy_absolute(p_original_path, backup_path) == OK


## Get backup path for a file with timestamp
static func get_backup_path(p_original_path: String) -> String:
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var filename = p_original_path.get_file()
	return BACKUPS_DIR.path_join("%s.%s.backup" % [filename, timestamp])


## Get user-specific profile path
static func get_user_profile_path(p_username: String) -> String:
	return PROFILES_DIR.path_join("%s_profile.json" % p_username.to_lower())


## Get temporary file path
static func get_temp_path(p_prefix: String = "temp") -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_id = randi() % 10000
	return CACHE_DIR.path_join("%s_%d_%d.tmp" % [p_prefix, timestamp, random_id])


## Check if path is within user data directory (security check)
static func is_valid_user_data_path(p_path: String) -> bool:
	return p_path.begins_with("user://data/") or p_path.begins_with("user://cache/")


## List files in directory with extension filter
static func list_files(p_directory: String, p_extension_filter: String = "json") -> Array:
	var files = []
	var dir = DirAccess.open(p_directory)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension() == p_extension_filter:
				files.append(p_directory.path_join(file_name))
			file_name = dir.get_next()

	return files


## Validate JSON data against required keys
static func validate_json_schema(p_data: Dictionary, p_required_keys: Array) -> bool:
	for key in p_required_keys:
		if not p_data.has(key):
			push_error("Missing required key in JSON data: " + str(key))
			return false
	return true


## Deep merge two dictionaries
static func merge_dictionaries(p_target: Dictionary, p_source: Dictionary) -> Dictionary:
	var result = p_target.duplicate(true)

	for key in p_source:
		if result.has(key) and result[key] is Dictionary and p_source[key] is Dictionary:
			result[key] = merge_dictionaries(result[key], p_source[key])
		else:
			result[key] = p_source[key]

	return result


## Copy file with backup option
static func copy_file(p_source: String, p_destination: String, p_create_backup: bool = false) -> bool:
	if not FileAccess.file_exists(p_source):
		push_error("Source file does not exist: " + p_source)
		return false

	if p_create_backup and FileAccess.file_exists(p_destination):
		create_backup(p_destination)

	if not _ensure_directory_for_file(p_destination):
		return false

	return DirAccess.copy_absolute(p_source, p_destination) == OK


## Delete file safely with optional backup
static func delete_file(p_path: String, p_create_backup: bool = true) -> bool:
	if not FileAccess.file_exists(p_path):
		return true  # File doesn't exist, consider it deleted

	if p_create_backup:
		create_backup(p_path)

	return DirAccess.remove_absolute(p_path) == OK


# Private helper methods

static func _ensure_directory_for_file(p_file_path: String) -> bool:
	var dir_path = p_file_path.get_base_dir()
	return _create_directory_if_not_exists(dir_path)


static func _create_directory_if_not_exists(p_dir_path: String) -> bool:
	if not DirAccess.dir_exists_absolute(p_dir_path):
		var error = DirAccess.make_dir_recursive_absolute(p_dir_path)
		if error != OK:
			push_error("Failed to create directory: " + p_dir_path)
			return false
		print("Created directory: " + p_dir_path)
	return true
