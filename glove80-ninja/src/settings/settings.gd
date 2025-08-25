extends Control

@onready var cursor_option: OptionButton = $Panel/VBoxContainer/CursorOption
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var save_btn: Button = $Panel/VBoxContainer/HBoxContainer/SaveBtn
@onready var cancel_btn: Button = $Panel/VBoxContainer/HBoxContainer/CancelBtn
@onready var reset_btn: Button = $Panel/VBoxContainer/HBoxContainer/ResetBtn
@onready var cursor_preview: RichTextLabel = $Panel/VBoxContainer/CursorPreview

var config_manager: Node
var original_values = {}


func _ready():
    config_manager = get_node("/root/ConfigManager")
    if config_manager:
        print("✅ ConfigManager found at: ", config_manager.get_path())
        
        # Check if signal exists and connect
        if config_manager.has_signal("config_changed"):
            print("✅ config_changed signal exists")
            config_manager.config_changed.connect(_on_config_changed)
        else:
            print("❌ config_changed signal NOT found")
    else:
        print("❌ ConfigManager NOT found at /root/ConfigManager")
    
    setup_cursor_options()
    load_current_settings()
    update_ui_state()
    add_to_group("practice_controllers")


func setup_cursor_options():
    cursor_option.clear()
    cursor_option.add_item("Block Cursor")
    cursor_option.set_item_metadata(0, "block")
    cursor_option.add_item("Box Cursor")
    cursor_option.set_item_metadata(1, "box")
    cursor_option.add_item("Line Cursor")
    cursor_option.set_item_metadata(2, "line")
    cursor_option.add_item("Underline Cursor")
    cursor_option.set_item_metadata(3, "underline")


func load_current_settings():
    var current_cursor = config_manager.get_setting("cursor_style", "block")
    for i in range(cursor_option.item_count):
        if cursor_option.get_item_metadata(i) == current_cursor:
            cursor_option.select(i)
            break
    
    # Store original values for cancel operation
    original_values["cursor_style"] = current_cursor


func _on_config_changed(_setting_name: String, _new_value):
    print("📢 SIGNAL RECEIVED: ", _setting_name, " = ", _new_value)
    print("📢 Current thread: ", OS.get_thread_caller_id())
    update_ui_state()


func update_ui_state():
    if config_manager:
        var has_unsaved = config_manager.has_unsaved_changes()
        print("UI update - has_unsaved: ", has_unsaved)
        
        # Debug: Check what's actually in unsaved_changes
        if config_manager.has_method("get_unsaved_changes"):
            var changes = config_manager.get_unsaved_changes()
            print("Unsaved changes content: ", changes)
        
        save_btn.disabled = !has_unsaved
        cancel_btn.disabled = !has_unsaved
        
        if has_unsaved:
            status_label.text = "Unsaved changes"
            status_label.add_theme_color_override("font_color", Color.YELLOW)
        else:
            status_label.text = "Settings saved"
            status_label.add_theme_color_override("font_color", Color.GREEN)
    else:
        print("❌ ConfigManager not available for UI update")


func _on_cursor_option_item_selected(p_index: int):
    var cursor_style = cursor_option.get_item_metadata(p_index)
    UserConfigManager.set_setting("cursor_style", cursor_style, true)  # Save immediately
    
    # Force immediate visual update
    # get_tree().call_group("practice_controllers", "update_display")
    update_cursor_preview(cursor_style)


func update_cursor_preview(p_style: String) -> void:
    var preview_text = ""
    match p_style:
        "block":
            preview_text = "[bgcolor=#555555][color=white]A[/color][/bgcolor] B C"
        "box":
            preview_text = "[border=2][color=#FF9900]A[/color][/border] B C"
        "line":
            preview_text = "[u][color=#FF9900]A[/color][/u] B C"
        "underline":
            preview_text = "[u][color=white]A[/color][/u] B C"
    
    cursor_preview.text = preview_text


func _on_save_btn_pressed():
    if config_manager.save_config():
        status_label.text = "Settings saved successfully!"
        status_label.add_theme_color_override("font_color", Color.GREEN)
        original_values["cursor_style"] = config_manager.get_setting("cursor_style", "block")
        update_ui_state()


func _on_cancel_btn_pressed():
    config_manager.discard_unsaved_changes()
    # Restore UI to original values
    var current_cursor = original_values.get("cursor_style", "block")
    for i in range(cursor_option.item_count):
        if cursor_option.get_item_metadata(i) == current_cursor:
            cursor_option.select(i)
            break
    status_label.text = "Changes cancelled"
    status_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
    update_ui_state()

func _on_reset_btn_pressed():
    # Reset to default values
    config_manager.set_setting("cursor_style", "block", true)
    load_current_settings()
    status_label.text = "Reset to default values"
    status_label.add_theme_color_override("font_color", Color.CYAN)
    update_ui_state()
