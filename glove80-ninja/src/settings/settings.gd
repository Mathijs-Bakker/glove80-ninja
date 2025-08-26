extends Control

@onready var cursor_option: OptionButton = $Panel/VBoxContainer/CursorOption
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var save_btn: Button = $Panel/VBoxContainer/HBoxContainer/SaveBtn
@onready var cancel_btn: Button = $Panel/VBoxContainer/HBoxContainer/CancelBtn
@onready var reset_btn: Button = $Panel/VBoxContainer/HBoxContainer/ResetBtn
@onready var cursor_preview: RichTextLabel = $Panel/VBoxContainer/CursorPreview

# Use class variable instead of local variable
var config_manager: Node
var original_values = {}


func _ready():
	config_manager = get_node("/root/UserConfigManager")
	if config_manager:
		print("✅ UserConfigManager found at: ", config_manager.get_path())
		
		# Connect to config changed signal
		if config_manager.has_signal("config_changed"):
			print("✅ config_changed signal exists")
			config_manager.config_changed.connect(_on_config_changed)
		else:
			print("❌ config_changed signal NOT found")
	else:
		print("❌ UserConfigManager NOT found")
	
	setup_cursor_options()
	load_current_settings()
	update_cursor_preview(config_manager.get_setting("cursor_style", "block"))
	update_ui_state()
	
	# ✅ CRITICAL: Connect the OptionButton signal
	if cursor_option:
		print("Connecting cursor_option signal...")
		cursor_option.item_selected.connect(_on_cursor_option_item_selected)
	else:
		print("❌ cursor_option is null!")


func _on_test_btn_pressed():
	print("=== TEST BUTTON PRESSED ===")
	print("Config manager: ", config_manager != null)
	print("Has set_setting method: ", config_manager.has_method("set_setting"))
	
	# Test direct method call
	config_manager.set_setting("test_setting", "test_value")
	print("UI state after test: ", config_manager.has_unsaved_changes())
	update_ui_state()


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
	if not config_manager:
		return
		
	var current_cursor = config_manager.get_setting("cursor_style", "block")
	print("Loading current settings - cursor: ", current_cursor)
	
	for i in range(cursor_option.item_count):
		if cursor_option.get_item_metadata(i) == current_cursor:
			cursor_option.select(i)
			print("Selected option index: ", i)
			break
	
	# Store original values for cancel operation
	original_values["cursor_style"] = current_cursor


func _on_config_changed(p_setting_name: String, p_new_value):
	print("📢📢📢 SIGNAL RECEIVED! Setting: ", p_setting_name, " Value: ", p_new_value)
	if p_setting_name == "cursor_style":
		update_cursor_preview(p_new_value)
	update_ui_state()


func update_ui_state():
	if config_manager and config_manager.has_method("has_unsaved_changes"):
		var has_unsaved = config_manager.has_unsaved_changes()
		print("UI update - has_unsaved: ", has_unsaved)
		print("Config manager valid: ", config_manager != null)
		
		save_btn.disabled = !has_unsaved
		cancel_btn.disabled = !has_unsaved
		
		if has_unsaved:
			status_label.text = "Unsaved changes"
			status_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			status_label.text = "Settings saved"
			status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		print("❌ ConfigManager issues - has_method: ", str(config_manager.has_method("has_unsaved_changes")) if config_manager else "no config manager")
		save_btn.disabled = true
		cancel_btn.disabled = true


func _on_cursor_option_item_selected(p_index: int):
	if not config_manager:
		return
		
	var cursor_style = cursor_option.get_item_metadata(p_index)
	print("Selected cursor style: ", cursor_style)
	
	# Get current value from config (not from UI)
	var current_cursor = config_manager.get_setting("cursor_style", "block")
	print("Current cursor in config: ", current_cursor)
	
	if current_cursor == cursor_style:
		print("No change needed - already set to: ", cursor_style)
		return
	
	# Call set_setting and force UI update
	config_manager.set_setting("cursor_style", cursor_style)
	
	# Force immediate UI update
	update_ui_state()
	update_cursor_preview(cursor_style)
	print("Cursor style changed to: ", cursor_style)


func update_cursor_preview(p_style: String) -> void:
	# For now, use text preview until we implement custom cursor in settings
	var preview_text = ""
	match p_style:
		"block":
			preview_text = "Block: [bgcolor=#555555][color=white]A[/color][/bgcolor]"
		"box":
			preview_text = "Box: [border=2][color=#FF9900]A[/color][/border]"
		"line":
			preview_text = "Line: │A"  # Using vertical line character
		"underline":
			preview_text = "Underline: [u][color=white]A[/color][/u]"
	
	cursor_preview.text = preview_text


func _on_save_btn_pressed():
	if config_manager and config_manager.has_method("save_config"):
		if config_manager.save_config():
			status_label.text = "Settings saved successfully!"
			status_label.add_theme_color_override("font_color", Color.GREEN)
			original_values["cursor_style"] = config_manager.get_setting("cursor_style", "block")
			update_ui_state()
		else:
			status_label.text = "Error saving settings!"
			status_label.add_theme_color_override("font_color", Color.RED)
	else:
		print("❌ save_config method not available")


func _on_cancel_btn_pressed():
	if config_manager and config_manager.has_method("discard_unsaved_changes"):
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
		update_cursor_preview(current_cursor)
	else:
		print("❌ discard_unsaved_changes method not available")


func _on_reset_btn_pressed():
	if not config_manager:
		return
		
	# Reset to default values
	config_manager.set_setting("cursor_style", "block", true)  # true = save immediately
	load_current_settings()
	update_cursor_preview("block")
	status_label.text = "Reset to default values"
	status_label.add_theme_color_override("font_color", Color.CYAN)
	update_ui_state()
