extends Node

## Handles text display with custom cursor node


@onready var sample_label: RichTextLabel
var cursor: Control
var config_manager: Node
var current_cursor_position: int = 0
var current_text: String = ""


func setup(p_label_node: RichTextLabel, p_config_node: Node) -> void:
	sample_label = p_label_node
	config_manager = p_config_node
	
	# Create new cursor instance
	var cursor_scene = preload("res://src/cursor/cursor.tscn")
	cursor = cursor_scene.instantiate()
	
	# Add cursor to the scene
	sample_label.add_child(cursor)
	cursor.visible = false
	print("TextDisplayManager setup with custom cursor")


func update_display(p_typing_data: Dictionary) -> void:
	if not sample_label:
		return
	
	current_text = p_typing_data.get("current_text", "")
	var user_input: String = p_typing_data.get("user_input", "")
	current_cursor_position = p_typing_data.get("current_index", 0)
	var mistakes: int = p_typing_data.get("mistakes", 0)
	
	# Update text display
	var display_text = generate_display_text(user_input, mistakes)
	sample_label.text = display_text
	
	# Always update cursor position, even for first character
	update_cursor_position()
	
	# Debug: Print cursor state
	print("Cursor update - position: ", current_cursor_position, 
		  " character: '", current_text[current_cursor_position] if current_cursor_position < current_text.length() else "N/A", 
		  "' visible: ", cursor.visible if cursor else false)


func force_cursor_update(p_position: int) -> void:
	if not cursor or current_text.is_empty():
		return
	
	current_cursor_position = p_position
	update_cursor_position()
	print("Force updated cursor to position: ", p_position)


func generate_display_text(p_user_input: String, p_mistakes: int) -> String:
	var display_text := ""
	
	for i in range(current_text.length()):
		if i < p_user_input.length():
			if p_user_input[i] == current_text[i]:
				display_text += "[color=green]" + current_text[i] + "[/color]"
			else:
				display_text += "[color=red]" + current_text[i] + "[/color]"
		else:
			display_text += current_text[i]
	
	return display_text


func update_cursor_position() -> void:
	print("update_cursor_position called - current_cursor_position: ", current_cursor_position)
	
	if current_cursor_position >= current_text.length() or not cursor:
		if cursor:
			cursor.visible = false
			print("Cursor hidden - beyond text length")
		return
	
	if current_text.is_empty():
		print("Cursor hidden - empty text")
		cursor.visible = false
		return
	
	# Calculate cursor position based on character index
	var cursor_char = current_text[current_cursor_position]
	print("Setting cursor character: '", cursor_char, "'")
	
	# Set character using direct property access with safety check
	if "character" in cursor:
		cursor.character = cursor_char
	else:
		print("Cursor does not have 'character' property")
	
	cursor.visible = true
	
	# Get text measurements - FIXED: Use the actual displayed text (with BBCode removed)
	var text_before_cursor = current_text.substr(0, current_cursor_position)
	var font = sample_label.get_theme_default_font()
	var font_size = sample_label.get_theme_font_size("normal_font_size")
	
	# Use get_string_size for accurate measurement - FIXED: Use plain text without BBCode
	var text_size = font.get_string_size(text_before_cursor, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	# Account for RichTextLabel padding and alignment
	var x_position = text_size.x
	var y_position = 0
	
	# Set cursor size based on font
	var font_height = font.get_height(font_size)
	cursor.size = Vector2(font.get_string_size(cursor_char, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 8, font_height)
	
	cursor.position = Vector2(x_position, y_position)
	
	print("Cursor updated - position: ", cursor.position, " character: '", cursor_char, "' text_before: '", text_before_cursor, "' text_size: ", text_size)


func update_cursor_style() -> void:
	if not cursor:
		return
		
	var cursor_style = UserConfigManager.get_setting("cursor_style", "block")
	
	# Set cursor style using direct property access with safety check
	if "cursor_style" in cursor:
		cursor.cursor_style = cursor_style
	else:
		print("Cursor does not have 'cursor_style' property")


func show_correct_feedback() -> void:
	if cursor and "pulse" in cursor:
		cursor.pulse()
	elif cursor:
		print("Cursor does not have 'pulse' method")


func show_incorrect_feedback() -> void:
	if cursor and "shake" in cursor:
		cursor.shake()
	elif cursor:
		print("Cursor does not have 'shake' method")


func set_cursor_active(p_active: bool) -> void:
	if cursor and "set_active" in cursor:
		cursor.set_active(p_active)
	elif cursor:
		print("Cursor does not have 'set_active' method")


func update_stats_display(p_stats: Dictionary, p_stats_label: Label) -> void:
	if p_stats_label and p_stats:
		var wpm = p_stats.get("wpm", 0.0)
		var accuracy = p_stats.get("accuracy", 0.0)
		var mistakes = p_stats.get("mistakes", 0)
		
		p_stats_label.text = "WPM: %.1f | Accuracy: %.1f%% | Mistakes: %d" % [wpm, accuracy, mistakes]


# Apply theme settings to the display
func apply_theme_settings() -> void:
	if not sample_label:
		return
	
	var theme = UserConfigManager.get_setting("theme", "dark")
	var font_size = UserConfigManager.get_setting("font_size", 24)
	
	match theme:
		"dark":
			sample_label.add_theme_color_override("default_color", Color.WHITE)
		"light":
			sample_label.add_theme_color_override("default_color", Color.BLACK)
		"high_contrast":
			sample_label.add_theme_color_override("default_color", Color.YELLOW)
	
	sample_label.add_theme_font_size_override("normal_font_size", font_size)
	update_cursor_style()
