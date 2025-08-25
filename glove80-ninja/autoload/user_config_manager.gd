extends Node

signal config_loaded()
signal config_saved()
signal config_changed(p_setting_name, p_new_value)

const CONFIG_PATH = FilePaths.APP_CONFIG

# Default configuration values
const DEFAULT_CONFIG = {
	"cursor_style": "block",
	"theme": "dark",
	"sound_volume": 80,
	"music_volume": 60,
	"sound_effects": true,
	"background_music": true,
	"difficulty": "medium",
	"show_hints": true,
	"font_size": 16,
	"typing_sounds": true,
	"keyboard_sounds": true,
	"auto_save": true,
	"auto_save_interval": 5,
	"language": "en"
}

var current_config: Dictionary = {}


func _ready() -> void:
	FilePaths.ensure_directories()
	load_config()


# Load configuration from file
func load_config() -> void:
	current_config = JSONManager.load_data(CONFIG_PATH, DEFAULT_CONFIG)
	config_loaded.emit()
	print("User config loaded: ", current_config)


# Save configuration to file
func save_config() -> bool:
	var success = JSONManager.save_data(CONFIG_PATH, current_config)
	if success:
		config_saved.emit()
		print("User config saved")
	else:
		push_error("Failed to save user config")
	
	return success


# Get a configuration value
func get_setting(p_setting_name: String, p_default_value = null):
	if current_config.has(p_setting_name):
		return current_config[p_setting_name]
	elif DEFAULT_CONFIG.has(p_setting_name):
		return DEFAULT_CONFIG[p_setting_name]
	else:
		return p_default_value


# Set a configuration value
func set_setting(p_setting_name: String, p_value, p_save_immediately: bool = false) -> void:
	if current_config.get(p_setting_name) == p_value:
		return  # No change needed
	
	current_config[p_setting_name] = p_value
	config_changed.emit(p_setting_name, p_value)
	
	if p_save_immediately:
		save_config()


# Reset to default configuration
func reset_to_defaults(p_save_immediately: bool = true) -> void:
	current_config = DEFAULT_CONFIG.duplicate(true)
	
	if p_save_immediately:
		save_config()
	
	print("Config reset to defaults")


# Export configuration for backup
func export_config(p_export_path: String) -> bool:
	return JSONManager.save_data(p_export_path, current_config)


# Import configuration from file
func import_config(p_import_path: String) -> bool:
	if not FileAccess.file_exists(p_import_path):
		return false
	
	var imported_config = JSONManager.load_data(p_import_path, {})
	if imported_config.is_empty():
		return false
	
	current_config = imported_config
	save_config()
	return true
