class_name SettingsService
extends RefCounted

static func get_cursor_style() -> String:
	var config = get_config_manager()
	return config.get_setting("cursor_style", "block") if config else "block"

static func get_config_manager() -> ConfigManager:
	return Engine.get_main_loop().root.get_node("/root/ConfigManager") as ConfigManager
