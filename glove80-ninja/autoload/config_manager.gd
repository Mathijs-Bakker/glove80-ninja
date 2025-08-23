# ConfigManager.gd (for autoload)
extends Node

# Configuration data structure
var config_data = {
    "cursor_style": "block",
}

# File path
const CONFIG_PATH = "user://typing_tutor_config.json"

# Signals
signal config_loaded()
signal config_saved()
signal config_changed(setting_name, new_value)

# Temporary storage for unsaved changes
var unsaved_changes = {}

func _ready():
    load_config()


func load_config():
    var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
    if file:
        var json_string = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        var error = json.parse(json_string)
        if error == OK:
            config_data = json.data
            print("Configuration loaded successfully")
            config_loaded.emit()
        else:
            print("Error parsing config: ", json.get_error_message())
            create_default_config()
    else:
        print("No config file found, creating default")
        create_default_config()


func save_config():
    # Apply unsaved changes first
    for key in unsaved_changes:
        config_data[key] = unsaved_changes[key]
    unsaved_changes.clear()
    
    var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
    if file:
        var json_string = JSON.stringify(config_data, "\t")
        file.store_string(json_string)
        file.close()
        print("Configuration saved successfully")
        config_saved.emit()
        return true
    else:
        print("Error saving config")
        return false


func create_default_config():
    config_data = {
        "cursor_style": "block"
    }
    save_config()


func get_setting(setting_name, default_value = null):
    if unsaved_changes.has(setting_name):
        return unsaved_changes[setting_name]
    return config_data.get(setting_name, default_value)


func set_setting(setting_name, value, save_immediately = false):
    unsaved_changes[setting_name] = value
    print("📢 Emitting config_changed signal: ", setting_name, " = ", value)
    config_changed.emit(setting_name, value)
    
    if save_immediately:
        save_config()


func has_unsaved_changes():
    return unsaved_changes.size() > 0


func discard_unsaved_changes():
    unsaved_changes.clear()
    print("Unsaved changes discarded")


func get_unsaved_changes():
    return unsaved_changes.duplicate()
