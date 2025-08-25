extends Node

## Manages user configuration settings


signal config_loaded()
signal config_saved()
signal config_changed(p_setting_name, p_new_value)

const CONFIG_PATH = "user://config/config.json"

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
var unsaved_changes: Dictionary = {}  # Ensure this exists


func _ready() -> void:
	load_config()


# Load configuration from file
func load_config() -> void:
	current_config = JSONManager.load_data(CONFIG_PATH, DEFAULT_CONFIG)
	unsaved_changes.clear()  # Clear any unsaved changes on load
	config_loaded.emit()
	print("User config loaded: ", current_config)


# Save configuration to file
func save_config() -> bool:
	# Apply unsaved changes to current config
	for key in unsaved_changes:
		current_config[key] = unsaved_changes[key]
	
	unsaved_changes.clear()  # Clear after saving
	
	var success = JSONManager.save_data(CONFIG_PATH, current_config)
	if success:
		config_saved.emit()
		print("User config saved")
	else:
		push_error("Failed to save user config")
	
	return success


# Get a configuration value
func get_setting(p_setting_name: String, p_default_value = null):
	# Check unsaved changes first, then current config, then defaults
	if unsaved_changes.has(p_setting_name):
		return unsaved_changes[p_setting_name]
	elif current_config.has(p_setting_name):
		return current_config[p_setting_name]
	elif DEFAULT_CONFIG.has(p_setting_name):
		return DEFAULT_CONFIG[p_setting_name]
	else:
		return p_default_value


# Set a configuration value
func set_setting(p_setting_name: String, p_value, p_save_immediately: bool = false) -> void:
	print("set_setting called: ", p_setting_name, " = ", p_value)
	
	# Get current value (including unsaved changes)
	var current_value = get_setting(p_setting_name)
	print("Current value: ", current_value, " New value: ", p_value)
	
	if current_value == p_value:
		print("No change needed")
		return  # No change needed
	
	# Store in unsaved changes
	unsaved_changes[p_setting_name] = p_value
	print("Unsaved changes now: ", unsaved_changes)
	
	config_changed.emit(p_setting_name, p_value)
	print("Signal emitted")
	
	if p_save_immediately:
		save_config()


# Check if there are unsaved changes
func has_unsaved_changes() -> bool:
	var has_changes = not unsaved_changes.is_empty()
	print("has_unsaved_changes: ", has_changes, " - changes: ", unsaved_changes)
	return has_changes


# Discard unsaved changes
func discard_unsaved_changes() -> void:
	print("Discarding unsaved changes: ", unsaved_changes)
	unsaved_changes.clear()
	print("Unsaved changes cleared")


# Reset to default configuration
func reset_to_defaults(p_save_immediately: bool = true) -> void:
	current_config = DEFAULT_CONFIG.duplicate(true)
	unsaved_changes.clear()
	
	if p_save_immediately:
		save_config()
	
	print("Config reset to defaults")


# Get the unsaved changes dictionary for debugging
func get_unsaved_changes() -> Dictionary:
	return unsaved_changes.duplicate()


# Export configuration for backup
func export_config(p_export_path: String) -> bool:
	# Include unsaved changes in export
	var export_data = current_config.duplicate(true)
	for key in unsaved_changes:
		export_data[key] = unsaved_changes[key]
	
	return JSONManager.save_data(p_export_path, export_data)


# Import configuration from file
func import_config(p_import_path: String) -> bool:
	if not FileAccess.file_exists(p_import_path):
		return false
	
	var imported_config = JSONManager.load_data(p_import_path, {})
	if imported_config.is_empty():
		return false
	
	current_config = imported_config
	unsaved_changes.clear()
	save_config()
	return true
