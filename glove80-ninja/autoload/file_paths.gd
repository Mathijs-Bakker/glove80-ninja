extends Node

## Centralized file path management for the entire application


# Base directories
const USER_DATA_DIR = "user://data/"
const CONFIG_DIR = "user://data/config/"
const PROFILES_DIR = "user://data/profiles/"
const STATS_DIR = "user://data/statistics/"
const SAVEGAMES_DIR = "user://data/savegames/"
const LESSONS_DIR = "user://data/lessons/"
const CACHE_DIR = "user://cache/"
const BACKUPS_DIR = "user://cache/backups/"

# Specific file paths
const APP_CONFIG = "user://data/config/app_config.json"
const UI_CONFIG = "user://data/config/ui_config.json"
const DEFAULT_PROFILE = "user://data/profiles/default_profile.json"
const DAILY_STATS = "user://data/statistics/daily_stats.json"
const OVERALL_STATS = "user://data/statistics/overall_stats.json"
const USER_PROGRESS = "user://data/lessons/user_progress.json"
const CUSTOM_LESSONS = "user://data/lessons/custom_lessons.json"
const SESSION_HISTORY = "user://data/statistics/session_history.json"

# Read-only default data (shipped with game)
const DEFAULT_LESSONS = "res://assets/data/default_lessons.json"
const DEFAULT_CONFIG = "res://assets/data/default_config.json"
const KEYBOARD_LAYOUTS = "res://assets/data/keyboard_layouts.json"


# Ensure all directories exist
func ensure_directories() -> void:
    var directories = [
        USER_DATA_DIR, CONFIG_DIR, PROFILES_DIR, 
        STATS_DIR, SAVEGAMES_DIR, LESSONS_DIR,
        CACHE_DIR, BACKUPS_DIR
    ]
    
    for dir_path in directories:
        if not DirAccess.dir_exists_absolute(dir_path):
            var error = DirAccess.make_dir_recursive_absolute(dir_path)
            if error != OK:
                push_error("Failed to create directory: " + dir_path)
            else:
                print("Created directory: " + dir_path)


# Get user-specific file path
func get_user_profile_path(p_username: String) -> String:
    return "user://data/profiles/%s_profile.json" % p_username.to_lower()


# Get save slot path
func get_save_slot_path(p_slot: int) -> String:
    return "user://data/savegames/slot_%d.json" % p_slot


# Get backup path for a file
func get_backup_path(p_original_path: String) -> String:
    var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
    var filename = p_original_path.get_file()
    return BACKUPS_DIR.path_join("%s.%s.backup" % [filename, timestamp])


# Get temporary file path
func get_temp_path(p_prefix: String = "temp") -> String:
    var timestamp = Time.get_unix_time_from_system()
    var random_id = randi() % 10000
    return CACHE_DIR.path_join("%s_%d_%d.tmp" % [p_prefix, timestamp, random_id])


# Check if path is within user data directory (security check)
func is_valid_user_data_path(p_path: String) -> bool:
    return p_path.begins_with("user://data/") or p_path.begins_with("user://cache/")


# Get relative path from user data directory
func get_relative_path(p_full_path: String) -> String:
    if p_full_path.begins_with("user://data/"):
        return p_full_path.substr("user://data/".length())
    elif p_full_path.begins_with("user://cache/"):
        return p_full_path.substr("user://cache/".length())
    return p_full_path
